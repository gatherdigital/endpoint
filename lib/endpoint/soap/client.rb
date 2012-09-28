module Endpoint
  module Soap

    class Client < ::Endpoint::Client

      CONTENT_TYPES = {
        1 => 'text/xml;charset=UTF-8',
        2 => 'application/soap+xml;charset=UTF-8'
      }.freeze

      attr_reader :version, :endpoint, :request_builder

      def initialize(version, endpoint, options = {})
        super options
        @version = version
        @endpoint = endpoint
        @request_builder = Endpoint::Soap::RequestBuilder.new(options[:builder] || {})
      end

      # Subclasses may override if they are capable of providing a better
      # Fault::Builder, which is useful when the reason for the fault might be
      # found in non-standard XML elements.
      def fault_builder
        Fault.const_get("Builder#{version}").new
      end

      # A layer above Endpoint::Client#perform_request, adds options for SOAP
      # HTTP requests. See also #request.
      #
      # Options are anything supported by Endpoint::Client#perform_request
      # (which includes those supported by HTTParty request methods) plus:
      #
      #   :action - The SOAPAction HTTP header value. Required for SOAP 1.1.
      #
      # Returns HTTParty::Response
      def soap_request(options = {})
        headers = { 'Content-Type' => CONTENT_TYPES[version] }
        if action = options.delete(:action)
          headers['SOAPAction'] = action
        elsif operation = options.delete(:operation)
          headers['SOAPAction'] = soap_action operation
        end

        if version == 1 && headers['SOAPAction'].blank?
          raise 'SOAPAction header value must be provided for SOAP 1.1'
        end

        request_options = { format: :xml, headers: headers }
        Response.new(version, perform_request(:post, endpoint, options.merge(request_options)), fault_builder).tap do |response|
          raise response.fault if response.fault?
          raise response.error if response.error?
        end
      end

      # Perform a request by constructing a SOAP document using the
      # #request_builder.
      #
      # Options are forwarded to #soap_request(), though there are a few
      # options for this method:
      #
      #   :body - Passed to request_builder. The SOAP XML produced by the
      #   builder is sent to soap_request.
      #
      #   :header - Passed to request_builder unmodified.
      #
      # Returns an Endpoint::Soap::Response.
      def request(options = {}, &body)
        soap_xml = request_builder.render(
          body: options.delete(:body) || body,
          header: options.delete(:header),
        )
        options[:body] = soap_xml
        soap_request options
      end
    end

    # Subclasses may override.
    #
    # Returns the SOAPAction HTTP header value for a given operation.
    def soap_action(operation)
      operation
    end

  end
end
