require 'spec_helper'

describe Endpoint::Soap::Fault::Builder1 do

  def fault(xml)
    described_class.new.build Nokogiri::XML(xml)
  end

  subject { fault %Q(
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
