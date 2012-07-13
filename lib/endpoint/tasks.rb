require 'endpoint/socks'

namespace :endpoint do
  namespace :proxy do
    def ensure_default_config
      Endpoint::Socks.default_config.tap do |c|
        raise "Enpoint::Socks.default_config must be set to use this task." if c.nil? || c.empty?
      end
    end

    desc 'Start SOCKS proxy over SSH for connecting to firewalled servers.'
    task :start do
      ensure_default_config
      Endpoint::Socks.start
    end

    desc 'Stop SOCKS proxy.'
    task :stop do
      ensure_default_config
      Endpoint::Socks.stop
    end
  end
end
