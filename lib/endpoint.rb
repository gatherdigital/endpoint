require 'httparty'
require 'nokogiri'
require 'nori'

Nori.strip_namespaces = true
Nori.parser = :nokogiri
Nori.configure do |config|
  config.convert_tags_to { |tag| tag.underscore.to_sym }
end

module Endpoint

end

require 'endpoint/version'

require 'endpoint/client'
require 'endpoint/http_error'
require 'endpoint/response_parser'
