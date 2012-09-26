require 'spec_helper'

describe Endpoint::Soap::Fault do

  def xml(s = '<Fault></Fault>')
    Nokogiri::XML(s)
  end

  let(:code) { 'Fault Code' }
  let(:reason) { 'Fault Reason' }

  def fault(xml = '<Fault></Fault>', code = 'Fault Code', reason = 'Fault Reason')
    described_class.new 1, Nokogiri::XML(xml), code, reason
  end

  it 'considers blank reason as nil' do
    described_class.new(1, xml, code, '').reason.should be_nil
  end

  it 'considers blank code as nil' do
    described_class.new(1, xml, '', reason).code.should be_nil
  end

  it 'responds to at_css navigation method within Fault' do
    described_class.new(1, xml('<Fault><whatever><stuff>value</stuff></whatever></Fault>'), code, reason).at_css('stuff').content.should == 'value'
  end
end
