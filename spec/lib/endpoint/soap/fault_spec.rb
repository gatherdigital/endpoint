require 'spec_helper'

describe Endpoint::Soap::Fault do

  subject { described_class.new version, response }

  let(:version) { 1 }
  let(:response) { Nokogiri::XML(fault) }
  let(:fault) { %Q(
    <Body>
      <stuff>not value</stuff>
      <Fault>
        <whatever><stuff>value</stuff></whatever>
        <faultcode>Fault Code!</faultcode>
        <faultstring>Fault String!</faultstring>
      </Fault>
    </Body>
  )}

  it 'responds to at_css navigation method within Fault' do
    subject.at_css('stuff').content.should == 'value'
  end

  describe 'SOAP 1.1' do
    it 'extracts code' do
      subject.code.should == 'Fault Code!'
    end

    it 'extracts reason' do
      subject.reason.should == 'Fault String!'
    end
  end

  describe 'SOAP 1.2' do
    let(:version) { 2 }
    let(:fault) { %Q(
      <Fault>
        <Code>Yo Code!</Code>
        <Reason>Yo Reason!</Reason>
      </Fault>
    )}

    it 'extracts code' do
      subject.code.should == 'Yo Code!'
    end

    it 'extracts reason' do
      subject.reason.should == 'Yo Reason!'
    end
  end
end
