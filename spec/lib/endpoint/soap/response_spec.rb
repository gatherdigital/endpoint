require 'spec_helper'

describe Endpoint::Soap::Response do
  subject { described_class.new 1, response }
  let(:response) { double 'HTTParty::Response', parsed_response: Nokogiri::XML('<Body></Body>') }

  describe 'fault_builder' do
    it 'answers the builder for version 1' do
      subject.fault_builder(1).should be_instance_of(Endpoint::Soap::Fault::Builder1)
    end

    it 'answers the builder for version 2' do
      subject.fault_builder(2).should be_instance_of(Endpoint::Soap::Fault::Builder2)
    end
  end
end
