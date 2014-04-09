module Endpoint
  module Socks
    class SocksConnectionAdapter < HTTParty::ConnectionAdapter
      def connection
        return super unless options[:http_proxyaddr]

        host = clean_host(uri.host)
        http = Net::HTTP::SOCKSProxy(options[:http_proxyaddr], options[:http_proxyport]).new(host, uri.port)
        http.use_ssl = ssl_implied?(uri)

        attach_ssl_certificates(http, options)

        if options[:timeout] && (options[:timeout].is_a?(Integer) || options[:timeout].is_a?(Float))
          http.open_timeout = options[:timeout]
          http.read_timeout = options[:timeout]
        end

        if options[:read_timeout] && (options[:read_timeout].is_a?(Integer) || options[:read_timeout].is_a?(Float))
          http.read_timeout = options[:read_timeout]
        end

        if options[:open_timeout] && (options[:open_timeout].is_a?(Integer) || options[:open_timeout].is_a?(Float))
          http.open_timeout = options[:open_timeout]
        end

        if options[:debug_output]
          http.set_debug_output(options[:debug_output])
        end

        if options[:ciphers]
          http.ciphers = options[:ciphers]
        end

        # Bind to a specific local address or port
        #
        # @see https://bugs.ruby-lang.org/issues/6617
        if options[:local_host]
          if RUBY_VERSION >= "2.0.0"
            http.local_host = options[:local_host]
          else
            Kernel.warn("Warning: option :local_host requires Ruby version 2.0 or later")
          end
        end

        if options[:local_port]
          if RUBY_VERSION >= "2.0.0"
            http.local_port = options[:local_port]
          else
            Kernel.warn("Warning: option :local_port requires Ruby version 2.0 or later")
          end
        end

        return http
      end
    end
  end
end
