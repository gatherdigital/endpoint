module Endpoint
  module Soap

    # Provides behavior for an Endpoint::Soap::Client that needs to send some
    # kind of authenitcation information in the SOAP Header element (an
    # access_token). The client should utilize #authenticated_request() in
    # place of #request() when the access_token is to be included in the SOAP
    # document Header element.
    #
    # A Client which includes this module must provide an implementation of the
    # following methods:
    #
    #   authenticate - Performs a SOAP request which answers an access_token of
    #   some kind.
    #
    #   auth_header(xml)  - Builds content for the SOAP document Header element
    #   which allows for authenticating a request.
    #
    #   expired_access_token?(Endpoint::Soap::Fault) - Must answer whether the
    #   fault represents a failure due to submitting an expired access_token.
    #
    module HeaderAuthentication
      def self.included(klass)
        klass.module_eval do
          attr_accessor :access_token
        end
      end

      # Perform a request by constructing a SOAP document using the
      # #request_builder, ensuring that the Client has been authenticated.
      # Handles case where existing access_token as expired.
      #
      # Options are the same as Endpoint::Soap::Client#request().
      #
      # Returns an Endpoint::Soap::Response.
      def authenticated_request(options = {}, &block)
        perform_authentication unless authenticated?
        begin
          request options.merge(header: security_header_method), &block
        rescue Endpoint::Soap::Fault => fault
          if expired_access_token?(fault)
            perform_authentication
            request options.merge(header: security_header_method), &block
          else
            raise fault
          end
        end
      end

      def perform_authentication
        @access_token = authenticate
        Endpoint::AuthenticationResult.new true
      rescue Endpoint::Soap::Fault
        Endpoint::AuthenticationResult.new false, $!.message
      end

      def authenticated?
        !!access_token
      end

      def security_header_method
        @security_header_method ||= self.method(:auth_header)
      end
    end

  end
end
