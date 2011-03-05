require 'nokogiri'
require 'httpclient'
require 'pp'
require 'json'
# require 'CGI'
require 'benchmark'

# USAGE : puts YelpScraper.new.yelpResults({'lat'=>37.337212,'long'=>-122.041017,'query'=>'Curry+Hoouse'})

# USAGE : puts YelpScraper.new.extractTermsForYelpBiz('/biz/garden-fresh-palo-alto')

# {"Result"=>["sweet and sour soup","scallion pancakes","style dish","general tsos chicken","kung pao","pepper chicken","orange beef","black pepper","yelp","peanut sauce","rest home","family style","eggplant","carnivores","leftovers","good food","tofu","mushrooms","co workers","guilt"]}

class YelpScraper
  
  def initalize
      
  end
  
  def runTests
    # pp yelpResults({'lat'=>37.337212,'long'=>-122.041017,'query'=>'Curry+Hoouse'})
    # pp extractTermsForYelpBiz('/biz/garden-fresh-palo-alto')
    # pp extractTermsForYelpBiz('/biz/curry-house-cupertino-2')
    pp extractTermsForYelpBiz('/biz/ten-ren-tea-cupertino')
    
    
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
      
      # No results found on Yelp for this place
      if res['events']['search.map.overlays'].empty?
        return nil
      end
      
      result_array = res['events']['search.map.overlays'].map{|e|
        if e['url'].nil?
          return nil
        else
          out = {
            :url=>e['url'],
            :hours=>e['hours'],
            :lat=>e['lat'],
            :lng=>e['lng'],
          }
          out.merge(parseYelpURL(e['url']))
        end
      }
      return result_array.compact.last # The last element is always the most relevant
  end
  
  def parseYelpURL(url)
    biz = yelpBiz(url)
    images = []
    begin
      biz.css('script').each{|script|
        if script.content.include? 'yelp.init.bizDetails.page'
            json = JSON.parse(script.content.gsub('yelp.init.wrapper("yelp.init.bizDetails.page", ','').gsub(');',''))
            json['slides'].each{|img| images << img['image_url'] }
        end
    }
    rescue
        # Rails.logger.info "no images, or no slideshow :(" if Rails
    end
    return {
      :name => biz.css('#bizInfoHeader h1').first.content,
      :rating => biz.css('#bizRating .rating img').first.attribute('title').content,
      :images=>images,
      :categories=> biz.css('#cat_display a').map{|a| a.content},
      :reviews => biz.css('#bizReviewsContent li.review').map{|review|
          {
            :rating => review.css('.rating img').first.attribute('title').content,
            :text => review.css('p.review_comment').first.content,
            :reviewer => {
              :image => review.css('.photoBox img').first.attribute('src').value,
              :name => review.css('a.reviewer_name').first.content,
              :profile_url => review.css('a.reviewer_name').first.attribute('href').value
            }
          }
      }
    }
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
      pp "http://www.yelp.com/#{path}?#{params.map{|k,v| k.to_s+'='+v.to_s}.join('&')}"
      getJSON("http://www.yelp.com/#{path}",params)
  end
  
  def extractTermsForYelpBiz(path)
    # reviews = YelpScraper.new.parseYelpURL('/biz/garden-fresh-palo-alto')[:reviews]
    reviews = parseYelpURL(path)[:reviews]
    extractTerms(reviews.map{|r|r[:text]}.join(' '))
  end
  
  def extractTerms(text)
    url = 'http://search.yahooapis.com/ContentAnalysisService/V1/termExtraction'
    params = {
      :appid=>'VdTLzn6q',
      :context=>text,
      :query =>'food',
      :output=>'json'
    }
    JSON.parse(HTTPClient.post_content(url,params))['ResultSet']
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
      Nokogiri::HTML(get(url))
  end

  def get(url,params={})
      o = {'User-Agent'=>'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'}
      # url = "http://184.106.211.251/index.php?url=#{CGI.escape(url)}"
      url = url+'?'+params.map{|k,v| k.to_s+'='+v.to_s}.join('&')
      url = URI.escape(url)
      url = CGI.escape(url)
      url = "http://72.2.118.126/index.php?url=#{url}"
      HTTPClient.new.get_content(url,params,o)
  end
  
  def getJSON(url,params)
      JSON.parse(get(url,params))
  end
  
end

# YelpScraper.new.runTests


