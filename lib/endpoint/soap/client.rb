module Endpoint
  module Soap

    class Client < ::Endpoint::Client

      CONTENT_TYPES = {
        1 => 'text/xml;charset=UTF-8',
        2 => 'application/soap+xml;charset=UTF-8'
      }.freeze

      attr_reader :version, :endpoint

      def initialize(version, endpoint, options = {})
        super options
        @version = version
        @endpoint = endpoint
      end

      # Options are anything supported by Endpoint::Client#perform_request
      # (which includes those supported by HTTParty request methods) plus:
      #
      #   :action - The SOAPAction header value.
      #
      # Returns HTTParty::Response
      def request(options = {})
        headers = { 'Content-Type' => CONTENT_TYPES[version] }
        if action = options.delete(:action)
          headers['SOAPAction'] = action
        elsif version == 1
          raise 'SOAPAction header value must be provided for SOAP 1.1'
        end
        request_options = { format: :xml, headers: headers }
        Response.new(version, perform_request(:post, endpoint, options.merge(request_options))).tap do |response|
          raise response.fault if response.fault?
          raise response.error if response.error?
        end
      end
    end

  end
end
