require 'spec_helper'

describe Endpoint::Soap::Fault::Builder1 do

  def fault(xml)
    described_class.new.build Nokogiri::XML(xml)
  end

  subject { fault %Q(
    <Body>
      <stuff>not value</stuff>
      <Fault>
        <whatever><stuff>value</stuff></whatever>
        <faultcode>Fault Code!</faultcode>
        <faultstring>Fault String!</faultstring>
      </Fault>
    </Body>
  )}

  it 'extracts code' do
    subject.code.should == 'Fault Code!'
  end

  it 'extracts reason' do
    subject.reason.should == 'Fault String!'
  end
end
