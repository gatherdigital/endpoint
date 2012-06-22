require 'endpoint/soap'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before do
    WebMock.disable_net_connect!
  end

  config.after do
    WebMock.allow_net_connect!
  end
end
