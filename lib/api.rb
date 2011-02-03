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
    
    def self.send_oauth_get_request(host = nil, path = nil, consumer_key = nil, consumer_secret = nil, token = nil, token_secret = nil)
      consumer = OAuth::Consumer.new(consumer_key, consumer_secret, :site => host)
      access_token = OAuth::AccessToken.new(consumer, token, token_secret)
      
      response = access_token.get(path).body
      
      puts response
    end
  end
end