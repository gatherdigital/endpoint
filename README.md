# Endpoint

A Gem we use to make connecting to APIs easier on us. It's opinionated.

## Installation

Add this line to your application's Gemfile:

    gem 'endpoint'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install endpoint

## Usage

To connect to an API, use either Endpoint::Client or Endpoint::Soap::Client.
You can subclass these if you like. If your API provider limits connections to
being from a specific IP address (they have a firewall hole poked for you), you
should look at using Endpoint::Socks.

### Endpoint::Client

### Endpoint::Soap::Client

### Endpoint::Socks

It's possible to set the config to use whenever a SOCKS proxy is needed. See
the documentation for explanation:

  Endpoint::Socks.default_config = {
    user: 'deploy',
    host: 'acceptable.server.com',
    server: '127.0.0.1',
    port: 9999
  }

Now you can run some client connecting code in a block:

  Endpoint::Socks.start do
    Endpoint::Client.new(
      server: '127.0.0.1',
      port: 9999
    )
  end

Or you can turn on the proxy and turn it off when you'd like:

  Rakefile:
    require 'endpoint/tasks'

  rake endpoint:proxy:start
  rake endpoint:proxy:stop

Of course, your code will still need to initialize the Endpoint::Client with
the correct proxy server and port. Additionally, you will need to make this
call before Net::HTTP will function with the proxy:

  require 'endpoint/socks'
  Endpoint::Socks.enable_net_http_socks_proxy


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
