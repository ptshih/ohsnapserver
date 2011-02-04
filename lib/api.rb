require 'rubygems'
require 'typhoeus'
require 'yajl/json_gem'
require 'oauth'

# https://github.com/dbalatero/typhoeus#readme

module API
  class Api
    def self.send_request(url = nil, method = :get, headers = nil, params = nil, timeout = 30, body = nil)
      begin
        response = Typhoeus::Request.get("http://www.google.com")
      
        puts response.code
        puts response.body
      rescue
        puts "send request failed"
        return false
      else
        return true
      end
    end
    
    def self.send_oauth_request(host = nil, path = nil, consumerKey = nil, consumerSecret = nil, token = nil, tokenSecret = nil)
      consumer = OAuth::Consumer.new(consumerKey, consumerSecret, :site => host)
      accessToken = OAuth::AccessToken.new(consumer, token, tokenSecret)
      
      response = accessToken.get(path).body
      
      return response
    end
    
    def self.parse_json(json)
      puts "Parsing JSON"
      parsedJson = JSON.parse(json)
      return parsedJson
    end
  end
end