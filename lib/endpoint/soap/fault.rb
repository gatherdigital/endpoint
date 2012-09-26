module Endpoint
  module Soap

    class Fault < StandardError

      class AbstractBuilder
        def build(response)
          fault_node = response.at_css('Fault')
          if fault_node
            code = extract_code fault_node rescue nil
            reason = extract_reason fault_node rescue nil
          end
          Fault.new version, fault_node, code, reason
        end
      end

      class Builder1 < AbstractBuilder
        def version; 1; end

        def extract_code(node)
          node.at_css('faultcode').content
        end

        def extract_reason(node)
          node.at_css('faultstring').content
        end
      end

      class Builder2 < AbstractBuilder
        def version; 2; end

        def extract_code(node)
          node.at_css('Code').content
        end

        def extract_reason(node)
          node.at_css('Reason').content
        end
      end

      # The version of SOAP.
      attr_reader :version

      # Returns the Nokogiri::Document of the SOAP response.
      attr_reader :response

      # Returns the SOAP fault code String.
      attr_reader :code

      # Returns the SOAP fault reason String.
      attr_reader :reason

      def initialize(version, node, code, reason)
        @version, @node = version, node
        self.code, self.reason = code, reason
        if occurred?
          super "SOAP fault (#{code}): #{reason || 'Reason not found in response.'}"
        else
          super 'SOAP fault not found in response.'
        end
      end

      def occurred?
        !!@node
      end

      def at_css(*args)
        occurred? ? @node.at_css(*args) : nil
      end

      private

      def code=(value)
        @code = value.blank? ? nil : value
      end

      def reason=(value)
        @reason = value.blank? ? nil : value
      end
    end

  end
end
