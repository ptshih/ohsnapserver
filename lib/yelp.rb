require 'nokogiri'
require 'httpclient'
require 'pp'
require 'json'

# USAGE : puts Yelp.new.yelpResults({'lat'=>37.337212,'long'=>-122.041017,'query'=>'Curry Hoouse'})
# returns the closest match


class Yelp
  
  def initalize
      
  end
  
  def search(params)
      yelpAPI('business_review_search',params)
  end
  
  def yelpResults(params)
      oneDegree = 69.046767 
      params['miles'] ||= 1.0
      range = (params['miles'] / oneDegree)/2
      bounds = "g:#{params['long']-range},#{params['lat']-range},#{params['long']+range},#{params['lat']+range}"
      res = yelp('search/snippet',{
          attrs:'',
          cflt:'',
          find_desc:params['query'],
          find_loc:'',
          l:bounds,
          mapsize:'small',
          parent_request_id:'6cf36ca09757e17b',
          rpp:'1',
          show_filters:1,
          sortby:'best_match',
          start:0
      })
      res['events']['search.map.overlays'].map{|e|
            biz = yelpBiz(e['url'])
            images = []
            begin
                biz.css('script').each{|script|
                    if script.content.include? 'yelp.init.bizDetails.page'
                        json = JSON.parse(script.content.gsub('yelp.init.wrapper("yelp.init.bizDetails.page", ','').gsub(');',''))
                        json['slides'].each{|img| images << img['image_url'] }
                    end
            }
            rescue
                Rails.logger.info "no images, or no slideshow :("
            end
          {
              :name => biz.css('#bizInfoHeader h1').first.content,
              :rating => biz.css('#bizRating .rating img').first.attribute('title').content,
              :url=>e['url'],
              :hours=>e['hours'],
              :lat=>e['lat'],
              :lng=>e['lng'],
              :images=>images,
              :reviews => biz.css('.review-content').map{|review|
                  {
                      :rating => review.css('.rating img').first.attribute('title').content,
                      :text => review.css('p.review_comment').first.content
                  }
              }
          }
      }.first
  end
  
  def yelpBiz(path)
    parseDoc("http://www.yelp.com/#{path}")
  end
  
  def yelpAPI(path,params)
      params['ywsid'] = 'JvPVrNi5skFeM-cKkS91pg';
      params['num_biz_requested']=20;
      pp getJSON("http://api.yelp.com/#{path}",params)['businesses'].first
  end
  
  def yelp(path,params)
      pp path,params
      getJSON("http://www.yelp.com/#{path}",params)
  end
  
  private
  
  def cacheable(key)
      out = Rails.cache.read(key)
      if out.nil?
        puts 'cache miss '+key
        out = yield 
      end
      Rails.cache.write(key,out,:ttl=>12.hours) unless out.nil?
      out
  end

  def parseDoc(url)
      Nokogiri::HTML(HTTPClient.new.get_content(url))
  end

  def get(url,params={})
      HTTPClient.new.get_content(url,params)
  end
  
  def getJSON(url,params)
      JSON.parse(get(url,params))
  end
  
end



