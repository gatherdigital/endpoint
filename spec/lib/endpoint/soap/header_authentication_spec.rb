require 'spec_helper'

describe Endpoint::Soap::HeaderAuthentication do

  class Client < Endpoint::Soap::Client
    include Endpoint::Soap::HeaderAuthentication

    def auth_header(xml)
      xml.MyAuth access_token
    end
  end

  def soap_authenticated_request(access_token)
    return <<-SOAP_AUTH
<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
  <env:Header>
    <env:MyAuth>#{access_token}</env:MyAuth>
  </env:Header>
  <env:Body>
    <env:Stuff>hi!</env:Stuff>
  </env:Body>
</env:Envelope>
SOAP_AUTH
  end


  let(:endpoint) { 'http://endpoint.com' }
  let(:fault_xml) { '<Envelope><Body><Fault><Code>INVALID TOKEN</Code><Reason>Simulated Fault</Reason></Fault></Body></Envelope>' }
  let(:soap_version) { 2 }

  let(:soap_response) {{
    status: 200, body: '<Envelope><Body></Body></Envelope>'
  }}

  let(:soap_fault_response) {{ body: fault_xml }}

  subject { Client.new soap_version, endpoint }

  context 'before request' do
    it 'establishes access_token' do
      access_token = 'access token'
      stub_request(:post, endpoint)
        .with(body: soap_authenticated_request(access_token))
        .to_return(soap_response)
      subject.should_receive(:authenticate).and_return(access_token)
      subject.authenticated_request {|xml| xml.Stuff 'hi!'}
    end

    it 'raises error on failure' do
      result = Endpoint::AuthenticationResult.new false, 'Me Message'
      subject.should_receive(:authenticate).and_return(result)
      expect do
        subject.authenticated_request {|xml| raise 'Never to be called' }
      end.to raise_error('Me Message')
    end

    it 're-authenticates expired access token' do
      subject.access_token = 'old token'
      stub_request(:post, endpoint)
        .with(body: soap_authenticated_request('old token'))
        .to_return(soap_fault_response)
      stub_request(:post, endpoint)
        .with(body: soap_authenticated_request('access token'))
        .to_return(soap_response)
      subject.should_receive(:authenticate).and_return('access token')
      subject.should_receive(:expired_access_token?).with(an_instance_of(Endpoint::Soap::Fault)).and_return(true)
      subject.authenticated_request {|xml| xml.Stuff 'hi!'}
    end
  end

  describe 'perform_authentication' do
    let(:fault) { Endpoint::Soap::Fault.new(soap_version, Nokogiri::XML(fault_xml), 'INVALID TOKEN', 'Simulated Fault') }

    it 'answers success when a token can be obtained' do
      subject.should_receive(:authenticate).and_return('access token')
      response = subject.perform_authentication
      response.success?.should == true
      response.message.should be_nil
    end

    it 'answers failure when a token cannot be obtained' do
      subject.should_receive(:authenticate).and_return(nil)
      response = subject.perform_authentication
      response.success?.should == false
      response.message.should_not be_nil
    end

    it 'answers failure when a blank token is obtained' do
      subject.should_receive(:authenticate).and_return('   ')
      response = subject.perform_authentication
      response.success?.should == false
      response.message.should_not be_nil
    end

    it 'answers failure when any fault occurs' do
      subject.should_receive(:authenticate).and_raise(fault)
      response = subject.perform_authentication
      response.success?.should == false
      response.message.should == fault.message
    end

    it 'allows subclass to answer Endpoint::AuthenticationResult for more control over message' do
      result = Endpoint::AuthenticationResult.new true
      result.access_token = 'Hello!'
      subject.should_receive(:authenticate).and_return(result)
      subject.perform_authentication.should eq(result)
      subject.access_token.should == 'Hello!'
    end
  end
end
