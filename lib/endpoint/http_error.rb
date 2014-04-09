module Endpoint

  class HttpError < StandardError
    def initialize(response, message = response.body)
      @response = response
      super "HTTP error (#{response.code})#{': ' + message unless !message || message.empty?}"
    end
  end

end
