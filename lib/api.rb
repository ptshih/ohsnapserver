require 'rubygems'
require 'typhoeus'
require 'yajl/json_gem'
require 'oauth'

# https://github.com/dbalatero/typhoeus#readme

module API
  class Api
    def send_request(url = nil, method = :get, headers = nil, params = nil, timeout = 30, body = nil)
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
    
    def send_oauth_request(host = nil, path = nil, consumer_key = nil, consumer_secret = nil, token = nil, token_secret = nil)
      consumer = OAuth::Consumer.new(consumer_key, consumer_secret, :site => host)
      oauth_access_token = OAuth::AccessToken.new(consumer, token, token_secret)
      
      response = oauth_access_token.get(path).body
      
      return response
    end
    
    def parse_json(json)
      puts "Parsing JSON"
      parsed_json = JSON.parse(json)
      return parsed_json
    end
  end
end