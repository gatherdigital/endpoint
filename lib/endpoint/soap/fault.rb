module Endpoint
  module Soap

    class Fault < StandardError

      # Returns the SOAP fault code String.
      attr_reader :code

      # Returns the SOAP fault reason String.
      attr_reader :reason

      # Returns the Nokogiri::Document of the SOAP response.
      attr_reader :response

      def initialize(version, response)
        @response = response
        if @fault_node = response.at_css('Fault')
          @code = @fault_node.at_css(version == 1 ? 'faultcode' : 'Code').content
          @reason = @fault_node.at_css(version == 1 ? 'faultstring' : 'Reason').content rescue nil
          super "SOAP fault (#{@code}): #{@reason || 'Reason not provided in response.'}"
        else
          super 'SOAP fault did not occur'
        end
      end

      def occurred?
        !!@fault_node
      end

      def at_css(*args)
        occurred? ? @fault_node.at_css(*args) : nil
      end
    end

  end
end
