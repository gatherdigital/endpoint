namespace :endpoint do
  namespace :proxy do
    desc 'Start SOCKS proxy over SSH for connecting to firewalled servers.'
    task :start do
      Endpoint::Socks.start
    end

    desc 'Stop SOCKS proxy.'
    task :stop do
      Endpoint::Socks.stop
    end
  end
end
