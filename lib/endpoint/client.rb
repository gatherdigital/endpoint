module Endpoint

  class Client
    include HTTParty

    attr_accessor :observer
    attr_accessor :observer_body_filters

    # Options:
    #
    #   :observer - Any object conforming to the the Endpoint::Observer API.
    #
    #   :observer_body_filters - A Hash of replacements for request/response
    #   body reported to observer. This allows for avoiding shipping
    #   sensitive information around the system.
    #
    #   :proxy - A Hash of options for the proxy configuration:
    #     :host - The proxy server host.
    #     :port - The proxy server port.
    #
    #   :timeout - The HTTP request timeout. Defaults to 500.
    #
    def initialize(options)
      @observer = options[:observer]
      @observer_body_filters = options[:observer_body_filters]
      @request_options = extract_request_options options, timeout: 500
    end

    # Arguments:
    #
    #   method - HTTParty method to invoke, like :get, :post, etc.
    #
    #   url - A String that is the full url, or a path relative to the base_uri
    #   of the options in options[:request].
    #
    # Options are anything supported by HTTParty request methods plus:
    #
    #   :observer_body_filters - A Hash containing replacements for the HTTP
    #   request body content. These are added to any associated with the client
    #   already.
    #
    # The options provided to initialize are utilized in each request, though
    # overridden by those provided to this method. This is convenient if you
    # would like to provide the same observer_body_filters for each request,
    # etc.
    #
    # Returns HTTParty::Response
    def perform_request(method, url, options)
      request_options = @request_options.merge extract_request_options(options)

      headers = request_options[:headers]
      unless headers.has_key?('Content-Length')
        headers['Content-Length'] = (request_options[:body] || '').size.to_s
      end

      parser = ResponseParser.new
      opts = { parser: parser }.merge(request_options)
      try_count = 0
      begin
        response = self.class.__send__(method, url, opts)
      rescue Timeout::Error, Errno::ECONNRESET => e
        try_count += 1
        if try_count < 5
          retry
        else
          raise "Too many failures attempting request. Last error was: #{e.message}"
        end
      end

      if observer = options[:observer] || self.observer
        observer_filters = options[:observer_body_filters] || {}
        if self.observer_body_filters
          observer_filters = self.observer_body_filters.merge(observer_filters)
        end

        observer.request method, response.request.uri.to_s,
          request_options.merge(
            body:filter_body(request_options[:body], observer_filters)
          )
        observer.response method, response.request.uri.to_s,
          :status => response.code,
          :body => filter_body(response.body, observer_filters),
          :headers => response.headers
      end

      yield response if block_given?

      response
    end

    def filter_body(body, filters)
      return body if filters.blank?
      body.dup.tap do |filtered|
        filters.each do |match,substitute|
          filtered.gsub! match, substitute
        end
      end
    end

    protected

    NON_REQUEST_OPTIONS = [:observer, :observer_body_filters, :proxy]
    def extract_request_options(options, defaults = {})
      defaults.tap do |opts|
        if proxy_options = options[:proxy]
          opts[:http_proxyaddr] = proxy_options[:server]
          opts[:http_proxyport] = proxy_options[:port]
        end
        options.each do |k,v|
          next if NON_REQUEST_OPTIONS.include?(k)
          opts[k] = v
        end
      end
    end
  end

end
