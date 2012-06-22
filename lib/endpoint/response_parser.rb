module Endpoint

  # A custom parser which allows us to answer Nokogiri::Document for XML.
  # Notice that we are creating instances and not using the Class-based
  # approach documented in HTTParty. This allows us to avoid hi-jacking XML
  # parsing.
  class ResponseParser
    attr_reader :exception

    def call(body, format)
      perform_parsing body, format
    end

    def perform_parsing(body, format)
      case format
      when :xml
        Nokogiri::XML(body)
      else
        HTTParty::Parser.call(body, format)
      end
    end
  end

end
