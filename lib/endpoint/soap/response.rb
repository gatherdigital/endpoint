module Endpoint
  module Soap

    class Response
      extend Forwardable

      def_delegators :@response, :code, :request, :response, :body, :headers
      def_delegators :@xml, :at_css, :css, :at_xpath, :xpath

      def initialize(version, response)
        @version = version
        @response = response
        @xml = response.parsed_response
        @xml.remove_namespaces!
      end

      def error
        return nil if @error == false
        if code >= 200 && code < 500
          @error = false
        else
          @error = ::Endpoint::HttpError.new(@response)
        end
      end

      def error?
        !!error
      end

      def fault
        @fault ||= fault_builder(@version).build(self)
      end

      # Subclasses may override if they are capable of providing a better
      # Fault::Builder, which is useful when the reason for the fault might be
      # found in non-standard XML elements.
      def fault_builder(version)
        Fault.const_get("Builder#{version}").new
      end

      def fault?
        fault.occurred?
      end

      def to_nori(options = {})
        nodes = nodes_from_options options
        raise "Found more than one node matching #{options.inspect}." if nodes.size > 1
        Nori.parse nodes.first.to_xml
      end

      def to_nori_array(options = {})
        nodes = nodes_from_options options
        nodes.map { |e| Nori.parse e.to_xml }
      end

      def to_hash(options = {})
        nodes = nodes_from_options options
        raise "Found more than one node matching #{options.inspect}." if nodes.size > 1
        MultiXml.parse nodes.first.to_xml
      end

      def to_hash_array(options = {})
        nodes = nodes_from_options options
        nodes.map { |e| MultiXml.parse e.to_xml }
      end

      def nodes_from_options(options)
        if css = options[:css]
          node = @xml.css css
        else
          node = @xml
        end
      end

      def to_s
        body.to_s
      end
    end

  end
end
