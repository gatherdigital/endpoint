module Endpoint

  class AuthenticationResult
    attr_reader :message

    def initialize(success, message = nil)
      @success, @message = success, message
    end

    def success?
      !!@success
    end
  end

end
