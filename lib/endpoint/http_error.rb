module Endpoint

  class HttpError < StandardError
    def initialize(response)
      @response = response
      super "HTTP error (#{response.code})#{': ' + response.body unless response.body.empty?}"
    end
  end

end
