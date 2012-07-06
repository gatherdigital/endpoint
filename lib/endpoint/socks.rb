require 'fileutils'

module Endpoint
  module Socks

    # Configure the default_config to use with the Proxy. Makes it convenient
    # to run a Proxy without having to pass a config.
    def self.default_config=(v)
      @default_config = v
    end

    def self.default_config
      @default_config
    end

    # Since we're using a SOCKS proxy, we may need to teach Net::HTTP to do
    # Proxy our way.
    #
    def self.enable_net_http_socks_proxy
      @enabled_net_http_socks_proxy ||= begin
        require 'socksify/http'
        class << Net::HTTP
          def Proxy(addr, port, user=nil, pass=nil)
            return self unless addr # See Net::HTTP.Proxy implementation
            SOCKSProxy(addr, port)
          end
        end
      end
    end

    # Start the proxy. If a work Block is given, it is called and then the
    # proxy is stopped. If no work is given, the proxy is left running.
    #
    def self.start(config=default_config, &work)
      enable_net_http_socks_proxy
      proxy = Proxy.new(config)
      proxy.start
      if work
        begin
          work.call
        ensure
          proxy.stop
        end
      end
    end

    def self.stop(config=default_config)
      Proxy.new(config).stop
    end

  end
end

require 'endpoint/socks/proxy'
require 'endpoint/socks/irb'
