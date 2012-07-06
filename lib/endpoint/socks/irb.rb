module Endpoint
  module Socks

    module IRB
      def self.extended(workspace)
        return unless workspace.proxy?
        workspace.proxy.print_status
        if workspace.proxy.running?
          Socks.enable_net_http_socks_proxy
        else
          puts "You can start the proxy using the command 'start_proxy'."
        end
      end

      attr_reader :proxy

      def proxy?
        !!proxy
      end

      def proxy
        @proxy ||= begin
          if config = Socks.default_config
            Socks::Proxy.new config
          end
        end
      end

      # Starts a Proxy. The proxy will be stopped at exit if it is
      # started during the current session.
      #
      def start_proxy
        if !proxy.running?
          Kernel.at_exit do
            proxy.stop
          end
        end
        Socks.enable_net_http_socks_proxy
        proxy.start
      end
    end

  end
end
