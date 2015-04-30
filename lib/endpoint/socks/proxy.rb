require 'fileutils'

module Endpoint
  module Socks

    class Proxy
      PID_PATH = File.expand_path('tmp/proxy.pid')

      attr_reader :config

      # Answers true if this instance is responsible for starting the SSH SOCKS
      # proxy process.
      #
      attr_reader :started

      # Create a Socks proxy.
      #
      # config
      #   :host - Required. The machine that we'll be proxying through.
      #   :user - Required. The username on the remote machine.
      #   :port - Required. The local port that should be connected to the remote machine.
      #   :server - Required. The local host name that clients should connect to.
      #   :pid_path - Optional. The path on your local machine to store the PID
      #     for monitoring and shutdown. Defaults to PID_PATH.
      #
      def initialize(config)
        @config = {
          pid_path:PID_PATH
        }.merge(config)
      end

      def command
        ['ssh', '-n', '-N', '-D', config[:port].to_s, "#{config[:user]}@#{config[:host]}"]
      end

      def pid
        @pid ||= begin
          FileUtils.mkdir_p File.dirname(config[:pid_path])
          File.exists?(config[:pid_path]) ? File.read(config[:pid_path]).to_i : nil
        end
      end

      def pid=(value)
        @pid = value
        File.open(config[:pid_path], 'w') {|f| f.write(value) } if value
      end

      def running?
        pid && !!Process.getpgid(pid) rescue false
      end

      def print_status(out=$stdout)
        if running?
          out.puts "SSH SOCKS proxy running as pid #{pid}."
        else
          out.puts 'SSH SOCKS proxy is not running.'
        end
      end

      # Answers true if the proxy is running after calling this command,
      # whether it was already or becomes so during invocation.
      #
      def start(verbose=true, out=$stdout)
        print_status out
        return true if running?

        out.puts "Starting with command '#{command.join(' ')}'..." if verbose
        self.pid = IO.popen(command).pid
        @started = true

        if verbose && running?
          out.puts "Initializing SSH SOCKS proxy at #{config[:server]}:#{config[:port]} with pid #{pid}..."
          sleep 5 # would like a better way to ensure it's ready - without this, work block cannot connect
          out.puts "Started SSH SOCKS proxy."
        elsif verbose
          out.puts "Failed to start SSH SOCKS proxy at #{config[:server]}:#{config[:port]}."
        end

        running?
      end

      # Terminates the SOCKS process associated with this instance. Answer true
      # if it were running, false if not.
      #
      def stop(verbose=true, out=$stdout)
        if running?
          begin
            Process.kill 'TERM', pid
          rescue
            # Nothing to do. The process is already dead.
          ensure
            File.delete config[:pid_path]
          end
          if verbose
            out.puts 'Terminated SSH SOCKS proxy.'
          end
          true
        else
          if verbose
            out.puts 'SSH SOCKS proxy does not appear to be running.'
          end
          false
        end
      end
    end

  end
end
