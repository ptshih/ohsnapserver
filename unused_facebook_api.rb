# Serialize the sharing
# API::FacebookApi.new.serialize_share(13412412, 4804606, 29302, "hello message")
def serialize_share(checkin_id=nil, facebook_id=nil, place_id=nil, message=nil)

  s = Share.find_or_initialize_by_place_id(place_id)
  s.facebook_id = facebook_id
  s.place_id = place_id
  s.message = message
  s.shared_at = Time.now
  s.save

  # Temporarily disabling map share for specific user target sharing and notification systems
  # create_new_share_map = []
  # share_facebook_id_array.each do |share_facebook_id|
  #   create_new_share_map << [checkin_id, share_facebook_id]
  # end
  # 
  # share_maps_columns = [:checkin_id, :facebook_id]
  # SharesMap.import share_maps_columns, create_new_share_map
  # 
  # self.serialize_notification(sharer_facebook_id, share_facebook_id_array, checkin_id, "checkin", nil)

end

# Serialize the notifications
def serialize_notification(sender_id=0, receiver_array_id=nil, notify_type=nil, notify_object_id=nil, message=nil)
  
  create_new_notification = []
  receiver_array_id.each do |receiver_id|
    create_new_notification << [sender_id, receiver_id, notify_type, notify_object_id, message, Time.now]
  end
  notification_columns = [:sender_id, :receiver_id, :notify_type, :notify_object_id, :message, :send_timestamp]
  Notification.import notification_columns, create_new_notification
  
end

# Params:
# User's facebook_id
# Percentage between 0.0 -> 1.0
def update_fetch_progress(facebook_id, progress)
  puts "updating #{facebook_id} fetch progress: #{progress}"
  u = User.find_by_facebook_id(facebook_id)
  if not u.nil?
    u.update_attribute('fetch_progress', progress)
  end

end

#
# APIS
#
def find_checkins_for_facebook_id_array_batch(facebook_id = nil, facebook_id_array = nil, since = nil)
  if facebook_id_array.nil? then
    facebook_id_array = [@@peter_id, @@tom_id, @@james_id]
    facebook_id_array = ["102167", "107491", "202402", "202451", "206635", "210258", "221423", "222383", "223314", "300994", "404120", "407230", "837181", "1203891", "1204271", "1205313", "1206669", "1207467", "1209924", "1212462", "1214835", "1215870", "1217270", "1217767", "1218796", "1229612", "1237074", "1302698", "2203609", "2414683", "2420700", "2502195", "2502827", "2504814", "2539351", "2602152", "3001631", "3200308", "3200338", "3200785", "3201209", "3207713", "3213585", "3213871", "3213930", "3215015", "3223008", "3224819", "3225115", "3225501", "3302615", "3307216", "3308028", "3312026", "3318595", "3323295", "3400229", "3407534", "3409627", "3414242", "3430753", "3619557", "4804600", "4804606", "4804969", "4805917", "4807345", "4809933", "5505430", "6002685", "6006398", "6010421", "6817010", "7903099", "8620430", "8621075", "8639036", "10703701", "10710317", "10717536", "10718558", "10723087", "10729766", "10731869", "12438683", "12803642", "12805273", "12822783", "13004004", "13704812", "14900845", "67800652", "68600483", "77001082", "500031833", "500676063", "501591312", "503265413", "506408584", "510849527", "543612099", "547177528", "558377300", "573953756", "589860486", "590245157", "591070603", "593399035", "610978642", "624067894", "628447811", "629960217", "645750651", "666112048", "705063052", "707267501", "712743335", "720886950", "745245646", "745938780", "780624163", "802745284", "817333087", "847735037", "883200586", "1008514568", "1017673909", "1059468090", "1067580021", "1099524954", "1121490493", "1155635614", "1184055409", "1224771465", "1316730161", "1321571526", "1483053421", "1653886798", "100000049912171", "100000199684521", "100000576881557", "100000721817834", "100001483789469", "100001893113244"]
    # facebook_id_array = ["8963", "15500", "102167", "107491", "113140", "124718", "200408", "202451", "206635", "221423", "223984", "300994", "304753", "404120", "407230", "602380", "602908", "700411", "700640", "700913", "804962", "806533", "902398", "907578", "926017", "1104245", "1204213", "1205313", "1207135", "1209345", "1215870", "1217270", "1217767", "1232357", "1237074", "1238132", "1302148", "1302698", "1305225", "1317243", "1500280", "1503126", "1602207", "1900323", "1901630", "1946902", "2203649", "2204941", "2205136", "2260313", "2404878", "2420700", "2502195", "2502827", "2504814", "2511909", "2519703", "2520511", "2535681", "2535961", "2539351", "2602139", "2602152", "3001341", "3001631", "3102907", "3207046", "3207713", "3213871", "3214263", "3223008", "3225501", "3309147", "3312630", "3313694", "3318595", "3400229", "3405555", "3407534", "3409627", "3414242", "3422207", "3430753", "3431548", "3500262", "3601361", "3624841", "4200185", "4800419", "4800558", "4801645", "4801649", "4804600", "4804606", "4805917", "4807345", "4809933", "5311725", "5400602", "5401293", "5404625", "5505430", "5722387", "6000997", "6001293", "6002470", "6006398", "6006769", "6006817", "6007206", "6009423", "6010195", "6010421", "6013940", "6020556", "6029659", "6101740", "6103147", "6313486", "6403474", "6817010", "7903099", "7906450", "7944583", "8106362", "8504876", "8620430", "8621075", "8639036", "8819965", "9001569", "9219543", "9300454", "9351864", "10500882", "10701381", "10703701", "10703965", "10705786", "10706085", "10706823", "10707429", "10707911", "10708143", "10708824", "10710317", "10710655", "10712133", "10713943", "10714527", "10717536", "10718558", "10723087", "10723888", "10724566", "10727107", "10729538", "10729766", "10731869", "10732097", "10734785", "11509277", "11710692", "12409925", "12438683", "12801350", "12801778", "12803642", "12804385", "12805273", "12822783", "13004004", "13300908", "13309538", "13601113", "13704812", "13705330", "13710035", "13727874", "13748822", "14900845", "15100199", "15102941", "16103897", "16910989", "19900101", "23709354", "24004576", "27201382", "31900543", "32402049", "32502647", "44404928", "67800652", "68600483", "72606041", "77001082", "217600253", "500031833", "501523903", "503392346", "504450120", "505935283", "506408584", "506672906", "508035217", "510849527", "512078507", "512930451", "515116258", "515772011", "516423668", "517656034", "523260804", "523680072", "529385152", "529767396", "530761351", "531021788", "535022497", "539825468", "543612099", "544881151", "545678688", "546492587", "546542494", "546567064", "546572064", "546631962", "546690648", "547091873", "547098754", "547177528", "547187391", "547272532", "548430564", "549195732", "550827394", "554061179", "554407734", "558377300", "565240108", "565859853", "566189037", "566664300", "569265917", "572521995", "572956856", "573953756", "574953924", "580937949", "589860486", "590245157", "590940415", "591070603", "594160450", "594274171", "594452024", "603927580", "605520271", "606541139", "610604803", "610978642", "618042063", "619680540", "624845905", "628235176", "628976871", "629730750", "629820318", "629960217", "642175690", "643298081", "659752530", "664598837", "666112048", "684786997", "686280655", "688007999", "689596293", "698640330", "699393049", "703427587", "705063052", "707765263", "711951229", "712743335", "713240181", "715882796", "720350220", "720886950", "731347173", "742596203", "743369432", "751377782", "756051583", "761010312", "763045077", "764619434", "768184036", "777725173", "778870130", "780624163", "789287731", "794495829", "794671958", "821640386", "829932247", "843615575", "845320400", "847735037", "883200586", "1006483796", "1007143495", "1008514568", "1020813223", "1031074695", "1037187187", "1041450082", "1041510153", "1055790362", "1056240014", "1059468090", "1083946504", "1153131614", "1157346411", "1171782424", "1224771465", "1276494059", "1294779053", "1316730161", "1364641590", "1393300306", "1397027770", "1433341178", "1452930023", "1491100934", "1524000010", "1543103529", "1553881511", "1556625823", "1636489309", "1640227273", "1653886798", "1682880020", "1682880037", "1682880038", "1746680919", "1772072139", "1846550208", "100000049912171", "100000098807776", "100000160899544", "100000257177602", "100000353950542", "100000452740095", "100000480064561", "100000500324298", "100000631459780", "100000721817834", "100001152622932", "100001158537314", "100001483789469", "100001493170272"];
  end

  if facebook_id.nil? then
    facebook_id = @@peter_id
  end

  puts "find checkins for facebook_id_array: #{facebook_id_array} with token: #{self.access_token}"


  headers_hash = Hash.new
  headers_hash['Accept'] = 'application/json'

  params_hash = Hash.new
  params_hash['access_token'] = self.access_token
  params_hash['fields'] = 'id,from,tags,place,message,application,created_time'
  params_hash['limit'] = 2000 # set this to a really high limit to get all results in one call
  if !since.nil? then
    params_hash['since'] = since.to_i
  end

  # progress indicator
  num_friends = facebook_id_array.count
  num_friends_serialized = 0

  place_id_array = Array.new

  facebook_id_array.each do |friend_id|
    # Each person has a different last_fetched_checkins timestamp

    r = Typhoeus::Request.new("#{@@fb_host}/#{friend_id}/checkins", :method => :get, :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

    # Run this block when the request completes
    r.on_complete do |response|
      puts "Request complete for friend checkins with friend_id: #{friend_id}"
      num_friends_serialized += 1
      puts "Printing body: #{response.body}"
      puts "Response code: #{response.code}"
      parsed_response = self.parse_json(response.body)

      # Parse checkins
      parsed_response['data'].each do |checkin|
        self.serialize_checkin(checkin)
        place_id_array << checkin['place']['id']
      end

      puts "\n\n\n\n======#{friend_id}======\n\n\n\n"

      # last fetched checkins only works for the current user
      # self.update_last_fetched_checkins(friend_id) # Update last_fetched_checkins timestamp for user
    end

    self.hydra.queue r # add the request to the queue
  end

  self.hydra.run # blocking call to run the queue

  # Serialize unique list of place_ids
  if !place_id_array.empty?
    self.find_places_for_place_id_array_batch(place_id_array.uniq)
  end
  
  # Correlate unique list of place_ids with yelp places
  # if !place_id_array.empty?
  #   puts "Start Yelp correlation"
  #   API::YelpApi.new.correlate_yelp_to_place_with_place_place_id_array(place_id_array.uniq)
  #   puts "End Yelp correlation"
  # end

end


def find_places_for_place_id_array_batch(place_id_array = nil)
  puts "Requesting places array: #{place_id_array}"
  
  if place_id_array.nil? then
    place_id_array = [121328401214612,57167660895] # cafe zoe
  end
  
  headers_hash = Hash.new
  headers_hash['Accept'] = 'application/json'

  params_hash = Hash.new
  params_hash['access_token'] = self.access_token
  params_hash['limit'] = 2000 # set this to a really high limit to get all results in one call
  
  place_id_array.each do |place_id|
    r = Typhoeus::Request.new("#{@@fb_host}/#{place_id}", :method => :get, :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
    
    # Run this block when the request completes
    r.on_complete do |response|
      puts "Request complete for place with place_id: #{place_id}"
      puts "Printing body: #{response.body}"
      puts "Response code: #{response.code}"
      parsed_response = self.parse_json(response.body)

      facebook_place = self.serialize_place(parsed_response)
      self.update_expires_at_place_id(place_id)
    end
    
    self.hydra.queue r # add the request to the queue
    
  end

  self.hydra.run # blocking call to run the queue
  
end


# Temporary
# API::FacebookApi.new.find_page_for_places_with_none
def find_page_for_places_with_none
  page_alias_array = []
  
  # Executing query to set picture_url to the picture if it is relevant
  query = "update places set picture_url = picture where picture like 'http://profile%'"
  mysqlresult = ActiveRecord::Base.connection.execute(query)
  
  Place.find(:all, :select=>"page_parent_alias, sum(like_count) as like_count, count(*) as place_count", :conditions=>"page_parent_alias!='' and picture_url is null", :order => "count(*) desc, sum(like_count) desc", :group=> "page_parent_alias",:limit=>50).each do |place|
    page_alias_array << place.page_parent_alias
    puts place.page_parent_alias
  end
  
  self.find_page_for_page_alias(page_alias_array)
end
