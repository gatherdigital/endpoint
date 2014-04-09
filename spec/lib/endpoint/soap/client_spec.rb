require 'spec_helper'

describe Endpoint::Soap::Client do
  subject { described_class.new version, endpoint, options }

  let(:version) { 2 }
  let(:endpoint) { 'http://endpoint.com' }
  let(:options) { {} }

  let(:soap_response) {{
    status: 200,
    body: '<Envelope><Body></Body></Envelope>'
  }}

  let(:soap_fault_response) {{
    status: 500,
    body: '<Envelope><Body><Fault><Code>Server</Code><Reason></Reason></Fault></Body></Envelope>'
  }}

  describe 'options' do
    let(:response) { double :response, code: 200, parsed_response: Nokogiri::XML(soap_response[:body]) }

    it 'has default options' do
      described_class.should_receive(:post) do |url, opts|
        opts.should include({
          timeout: 500
        })
        response
      end
      subject.request
    end

    describe 'custom' do
      let(:options) {{
        timeout: 501,
        proxy: { server: 'host.name', port: '3929' }
      }}

      it 'uses provided options' do
        described_class.should_receive(:post) do |url, opts|
          opts[:timeout].should == 501
          response
        end
        subject.request
      end

      it 'extracts proxy options' do
        described_class.should_receive(:post) do |url, opts|
          opts[:http_proxyaddr].should == 'host.name'
          opts[:http_proxyport].should == '3929'
          response
        end
        subject.request
      end
    end
  end

  describe 'request' do
    it 'includes Content-Length header' do
      body = 'hello there you all'
      soap = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<env:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\">\n  <env:Body>hello there you all</env:Body>\n</env:Envelope>\n"
      stub_request(:post, endpoint)
        .with(headers: { 'Content-Length' => soap.size }, body: soap)
        .to_return(soap_response)
      subject.request body: body
    end

    it 'retries when Timeout::Error' do
      stub_request(:post, endpoint).to_timeout.then.to_return(soap_response)
      subject.request
    end

    it 'retries Timeout::Error only 5 times' do
      stub_request(:post, endpoint).to_timeout.times(5)
      lambda do
        subject.request
      end.should raise_error(/Too many failures.*execution expired/)
    end

    it 'retries when Errno::ECONNRESET' do
      stub_request(:post, endpoint).to_raise(Errno::ECONNRESET).then.to_return(soap_response)
      subject.request
    end

    it 'retries Errno::ECONNRESET only 5 times' do
      stub_request(:post, endpoint).to_raise(Errno::ECONNRESET).times(5)
      expect do
        subject.request
      end.to raise_error(/Too many failures.*Connection reset by peer/)
    end

    it 'retries 404 only 5 times' do
      stub_request(:post, endpoint)
        .to_return({ status: 404, body: '<html></html>' })
        .times(5)
      expect do
        subject.request
      end.to raise_error(/Too many failures.*404/)
    end
  end

  describe 'SOAP 1.1' do
    let(:version) { 1 }
    let(:request_options) {{
      action: 'http://host.com/action'
    }}
    let(:soap_fault_response) {{
      status: 500,
      body: '<Envelope><Body><Fault><faultcode>Server</faultcode><faultstring></faultstring></Fault></Body></Envelope>'
    }}

    it 'includes Content-Type header for SOAP 1.1' do
      stub_request(:post, endpoint)
        .with(headers: { 'Content-Type' => 'text/xml;charset=UTF-8' })
        .to_return(soap_response)
      subject.request request_options
    end

    it 'includes SOAPAction header' do
      stub_request(:post, endpoint)
        .with(headers: { 'SOAPAction' => 'http://host.com/action' })
        .to_return(soap_response)
      subject.request request_options
    end

    it 'raises error when no SOAPAction header provided' do
      expect {
        subject.request
      }.to raise_error(/SOAPAction/)
    end

    it 'raises error when Fault' do
      stub_request(:post, endpoint).to_return(soap_fault_response)
      expect {
        subject.request request_options
      }.to raise_error(Endpoint::Soap::Fault, /Server/)
    end

    it 'answers the builder for version 1' do
      subject.fault_builder.should be_instance_of(Endpoint::Soap::Fault::Builder1)
    end
  end

  describe 'SOAP 1.2' do
    let(:version) { 2 }

    it 'includes Content-Type header for SOAP 1.2' do
      stub_request(:post, endpoint)
        .with(headers: { 'Content-Type' => 'application/soap+xml;charset=UTF-8' })
        .to_return(soap_response)
      subject.request
    end

    it 'raises error when Fault' do
      stub_request(:post, endpoint).to_return(soap_fault_response)
      expect {
        subject.request
      }.to raise_error(Endpoint::Soap::Fault, /Server/)
    end

    it 'answers the builder for version 2' do
      subject.fault_builder.should be_instance_of(Endpoint::Soap::Fault::Builder2)
    end
  end

  describe 'observer' do
    let(:observer) do
      double('Observer').tap do |o|
        o.stub(:request)
        o.stub(:response)
      end
    end

    before do
      subject.observer = observer
      stub_request(:post, endpoint)
        .to_return(soap_response)
    end

    describe 'notification' do
      after { subject.request }

      it 'is made on request' do
        observer.should_receive(:request) do |method, url, options|
          method.should == :post
          url.should == endpoint
          options.should have_key(:body)
          options.should have_key(:headers)
        end
      end

      it 'is made on response' do
        observer.should_receive(:response) do |method, url, options|
          method.should == :post
          url.should == endpoint
          options.should have_key(:status)
          options.should have_key(:body)
          options.should have_key(:headers)
        end
      end
    end

    describe 'notification of errors' do
      it 'is made on soap fault' do
        stub_request(:post, endpoint).to_return(soap_fault_response)
        observer.should_receive(:request)
        observer.should_receive(:response)
        lambda do
          subject.request
        end.should raise_error(Endpoint::Soap::Fault)
      end

      it 'is made on HTTP errors' do
        stub_request(:post, endpoint).to_return(status: 500)
        observer.should_receive(:request)
        observer.should_receive(:response)
        lambda do
          subject.request
        end.should raise_error(Endpoint::HttpError)
      end
    end

    describe 'filters' do
      specify 'are applied to requests' do
        observer.should_receive(:request) do |method, url, options|
          options[:body].should =~ /stuff blah stuff/
        end
        subject.request body: 'stuff password stuff', observer_body_filters:{'password' => 'blah'}
      end

      specify 'are applied to responses' do
        stub_request(:post, endpoint).to_return(body: '<Envelope><Body>stuff password stuff</Body></Envelope>')
        observer.should_receive(:response) do |method, url, options|
          options[:body].should =~ /stuff blah stuff/
        end
        subject.request body: 'the request', observer_body_filters:{'password' => 'blah'}
      end
    end

    describe 'body parse errors' do
      before { Endpoint::ResponseParser.any_instance.should_receive(:perform_parsing).and_raise('error parsing') }

      after do
        lambda do
          subject.request
        end.should raise_error('error parsing')
      end

      it 'should notify request when request fails' do
        observer.should_receive(:request)
      end

      it 'should notify response when request fails' do
        observer.should_receive(:response)
      end
    end
  end

end
