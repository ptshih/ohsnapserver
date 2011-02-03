require 'rubygems'
require 'typhoeus'
require 'yajl/json_gem'
require 'oauth'

# https://github.com/dbalatero/typhoeus#readme

module API
  class Api
    def self.send_request(url = nil, method = :get, headers = nil, params = nil, timeout = 30, body = nil)
      begin
        # JSON.parse(HTTPClient.new.get_content(path,params))
        # JSON.parse(Zlib::GzipReader.new(StringIO.new(HTTPClient.new.get_content(path,params,extheader))).read)
        # it seems the gzip response is unreliable, so we need to check the response encoding
        # , :headers => { 'Accept-Encoding' => 'gzip' }
        response = Typhoeus::Request.get("http://www.google.com")
        
        # p response.content
        # contentType = response.contenttype
        encoding = response.headers_hash["Content-Encoding"]
        puts "Encoding: #{encoding}"

        if encoding.include? "gzip"
          puts "found gzip response"
          # parsedResponse = JSON.parse(Zlib::GzipReader.new(StringIO.new(response.body)).read)
        else
          puts "found text response"
          # parsedResponse = JSON.parse(response.body)
        end

        puts response.code
        puts response.body
        return nil
      rescue
        puts "send request failed"
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