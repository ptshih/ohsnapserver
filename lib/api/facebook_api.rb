module API
  class FacebookApi < Api

    # Peter's access token
    @@peter_access_token = "H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA"
    @@james_access_token = "132514440148709%257Cf09dd88ba268a8727e4f3fd5-645750651%257Ck21j0yXPGxYGbJPd0eOEMTy5ZN4"
    @@tom_access_token = "132514440148709|ddfc7b74179c6fd2f6e081ff-4804606|9SUyWXArEX9LFCAuY3DoFDvhgl0"
    @@moone_access_token = "132514440148709|22ebfa70b9a561d421c076fe-100002025298734|dJd8XJJg4p67Jh_lRFkkgEHX4Go"

    @@fb_host = 'https://graph.facebook.com'
    @@peter_id = 548430564
    @@james_id = 645750651
    @@tom_id = 4804606
    @@moone_id = 100002025298734

    @@peter_latitude = 37.765223405331
    @@peter_longitude = -122.45003812016

    attr_accessor :access_token, :hydra

    def initialize(access_token = nil)
      if access_token.nil? then access_token = @@peter_access_token end
      self.access_token = access_token

      self.hydra = Typhoeus::Hydra.new
    end

    # Just some notes here
    # 1. A single user signs on
    # 2. We fetch the user's friends list
    # 3. Create User entries for user and friends
    # 4. Create Friend entries for all friends for the user
    # 5. We fetch all checkins for the user and all his friends
    # 6. When we parse checkins, we also need to parse tagged_users (which may or may not be his friend)
    # 7. We don't want to create User entries for tagged_users who don't already exist because they are not friends (no access), we only have their name/id
    # 8. Tagged users who are not friends will show up in a checkin, but will be un-interactable (need to check in the API, our DB won't represent this)

    # Create or update checkin in model/database
    def serialize_checkin(checkin)
      puts "serializing checkin with id: #{checkin['id']}"
      c = Checkin.find_or_initialize_by_checkin_id(checkin['id'])
      c.checkin_id = checkin['id']
      c.facebook_id = checkin['from']['id']
      c.place_id = checkin['place']['id']
      c.app_id = checkin.has_key?('application') ? (checkin['application'].nil? ? nil : checkin['application']['id']) : nil
      c.message = checkin.has_key?('message') ? checkin['message'] : nil
      c.created_time = Time.parse(checkin['created_time'].to_s)
      c.save

      # Serialize App
      if checkin.has_key?('application') && !checkin['application'].nil? then
        self.serialize_app(checkin['application'])
      end

      # Serialize Tagged Users
      if checkin.has_key?('tags')
        checkin['tags']['data'].each do |t|
          self.serialize_tagged_user(t, checkin['id'])
        end
      end

      # Send request for Facebook Place
      # Use a non-blocking HTTP queue here
      # self.find_place_for_place_id(checkin['place']['id'])
    end

    # Create or update tagged friend
    def serialize_tagged_user(tagged_user, checkin_id)
      puts "serializing tagged user #{tagged_user} for checkin: #{checkin_id}"
      t = TaggedUser.find_or_initialize_by_checkin_id(tagged_user['id'])
      t.facebook_id = tagged_user['id']
      t.checkin_id = checkin_id
      t.name = tagged_user['name']
      t.save
    end

    # Create or update place in model/database
    def serialize_place(place)
      puts "serializing place with id: #{place['id']}"
      p = Place.find_or_initialize_by_place_id(place['id'])
      p.place_id = place['id']
      p.name = place['name']
      p.lat = place['location']['latitude']
      p.lng = place['location']['longitude']
      p.street = place['location']['street']
      p.city = place['location']['city']
      p.state = place['location']['state']
      p.country = place['location']['country']
      p.zip = place['location']['zip']
      p.raw_hash = place
      p.expires_at = Time.now + 1.days
      p.save
    end

    # Create or update app in model/database
    def serialize_app(app)
      puts "serializing app with id: #{app['id']}"
      a = App.find_or_initialize_by_app_id(app['id'])
      a.app_id = app['id']
      a.name = app['name']
      a.save
    end

    # Create or update user
    def serialize_user(user, access_token = nil)
      puts "serializing user with id: #{user['id']}"
      u = User.find_or_initialize_by_facebook_id(user['id'])
      if not access_token.nil? then u.access_token = access_token end
      u.facebook_id = user['id']
      u.third_party_id = user['third_party_id']
      u.full_name = user.has_key?('name') ? user['name'] : nil
      u.first_name = user.has_key?('first_name') ? user['first_name'] : nil
      u.last_name = user.has_key?('last_name') ? user['last_name'] : nil
      u.gender = user.has_key?('gender') ? user['gender'] : nil
      u.locale = user.has_key?('locale') ? user['locale'] : nil
      u.verified = user.has_key?('verified') ? user['verified'] : nil
      u.save

      return u
    end

    # Create or update friend
    def serialize_friend(friend, facebook_id, degree)
      puts "serializing friend with id: #{friend['id']}"
      f = Friend.where("facebook_id = #{facebook_id} AND friend_id = #{friend['id']}").limit(1).first
      if f.nil?
        f = Friend.create(
          :facebook_id => facebook_id,
          :friend_id => friend['id'],
          :degree => degree
        )
      end

      return f
    end

    def update_last_fetched_checkins(facebook_id)
      puts "updating #{facebook_id} last fetched checkins"
      u = User.find_by_facebook_id(facebook_id)
      if not u.nil?
        u.update_attribute('last_fetched_checkins', Time.now)
      end
    end

    def update_last_fetched_friends(facebook_id)
      puts "updating #{facebook_id} last fetched friends"
      u = User.find_by_facebook_id(facebook_id)
      if not u.nil?
        u.update_attribute('last_fetched_friends', Time.now)
      end
    end

    def update_expires_at_place_id(place_id)
      puts "updating #{place_id} last fetched time"
      p = Place.find_by_place_id(place_id)
      if not p.nil?
        p.update_attribute('expires_at', Time.now)
      end
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
    # API CALLS
    #

    # Finds all checkins for one user
    # https://graph.facebook.com/548430564/checkins?access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def find_checkins_for_facebook_id(facebook_id = nil, since = false)
      if facebook_id.nil? then facebook_id = @@peter_id end

      puts "find checkins for facebook_id: #{facebook_id}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['fields'] = 'id,from,tags,place,message,application,created_time'
      if since then
        u = User.find_by_facebook_id(facebook_id)
        if not u.last_fetched_checkins.nil? then
          params_hash['since'] = u.last_fetched_checkins.to_i
        end
      end


      response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}/checkins", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = self.parse_json(response.body)
      puts "Response from facebook: #{response.body}"
      puts "Respone status code: #{response.code}"
      place_id_array = Array.new
      #puts "Showing parsed response: #{parsed_response}"

      # Parse checkins
      parsed_response['data'].each do |checkin|
        self.serialize_checkin(checkin)
        place_id_array << checkin['place']['id']
      end

      # puts "#{place_id_array}"

      # Serialize unique list of place_ids
      if !place_id_array.empty?
        self.find_places_for_place_id_array_batch(place_id_array.uniq)
      end

      # Update last_fetched_checkins timestamp for user
      self.update_last_fetched_checkins(facebook_id)
    end

    def find_checkins_for_facebook_id_array_batch(facebook_id = nil, facebook_id_array = nil, since = false)
      if facebook_id_array.nil? then
        facebook_id_array = [@@peter_id, @@tom_id, @@james_id]
        facebook_id_array = ["102167", "107491", "202402", "202451", "206635", "210258", "221423", "222383", "223314", "300994", "404120", "407230", "837181", "1203891", "1204271", "1205313", "1206669", "1207467", "1209924", "1212462", "1214835", "1215870", "1217270", "1217767", "1218796", "1229612", "1237074", "1302698", "2203609", "2414683", "2420700", "2502195", "2502827", "2504814", "2539351", "2602152", "3001631", "3200308", "3200338", "3200785", "3201209", "3207713", "3213585", "3213871", "3213930", "3215015", "3223008", "3224819", "3225115", "3225501", "3302615", "3307216", "3308028", "3312026", "3318595", "3323295", "3400229", "3407534", "3409627", "3414242", "3430753", "3619557", "4804600", "4804606", "4804969", "4805917", "4807345", "4809933", "5505430", "6002685", "6006398", "6010421", "6817010", "7903099", "8620430", "8621075", "8639036", "10703701", "10710317", "10717536", "10718558", "10723087", "10729766", "10731869", "12438683", "12803642", "12805273", "12822783", "13004004", "13704812", "14900845", "67800652", "68600483", "77001082", "500031833", "500676063", "501591312", "503265413", "506408584", "510849527", "543612099", "547177528", "558377300", "573953756", "589860486", "590245157", "591070603", "593399035", "610978642", "624067894", "628447811", "629960217", "645750651", "666112048", "705063052", "707267501", "712743335", "720886950", "745245646", "745938780", "780624163", "802745284", "817333087", "847735037", "883200586", "1008514568", "1017673909", "1059468090", "1067580021", "1099524954", "1121490493", "1155635614", "1184055409", "1224771465", "1316730161", "1321571526", "1483053421", "1653886798", "100000049912171", "100000199684521", "100000576881557", "100000721817834", "100001483789469", "100001893113244"]
        # facebook_id_array = ["8963", "15500", "102167", "107491", "113140", "124718", "200408", "202451", "206635", "221423", "223984", "300994", "304753", "404120", "407230", "602380", "602908", "700411", "700640", "700913", "804962", "806533", "902398", "907578", "926017", "1104245", "1204213", "1205313", "1207135", "1209345", "1215870", "1217270", "1217767", "1232357", "1237074", "1238132", "1302148", "1302698", "1305225", "1317243", "1500280", "1503126", "1602207", "1900323", "1901630", "1946902", "2203649", "2204941", "2205136", "2260313", "2404878", "2420700", "2502195", "2502827", "2504814", "2511909", "2519703", "2520511", "2535681", "2535961", "2539351", "2602139", "2602152", "3001341", "3001631", "3102907", "3207046", "3207713", "3213871", "3214263", "3223008", "3225501", "3309147", "3312630", "3313694", "3318595", "3400229", "3405555", "3407534", "3409627", "3414242", "3422207", "3430753", "3431548", "3500262", "3601361", "3624841", "4200185", "4800419", "4800558", "4801645", "4801649", "4804600", "4804606", "4805917", "4807345", "4809933", "5311725", "5400602", "5401293", "5404625", "5505430", "5722387", "6000997", "6001293", "6002470", "6006398", "6006769", "6006817", "6007206", "6009423", "6010195", "6010421", "6013940", "6020556", "6029659", "6101740", "6103147", "6313486", "6403474", "6817010", "7903099", "7906450", "7944583", "8106362", "8504876", "8620430", "8621075", "8639036", "8819965", "9001569", "9219543", "9300454", "9351864", "10500882", "10701381", "10703701", "10703965", "10705786", "10706085", "10706823", "10707429", "10707911", "10708143", "10708824", "10710317", "10710655", "10712133", "10713943", "10714527", "10717536", "10718558", "10723087", "10723888", "10724566", "10727107", "10729538", "10729766", "10731869", "10732097", "10734785", "11509277", "11710692", "12409925", "12438683", "12801350", "12801778", "12803642", "12804385", "12805273", "12822783", "13004004", "13300908", "13309538", "13601113", "13704812", "13705330", "13710035", "13727874", "13748822", "14900845", "15100199", "15102941", "16103897", "16910989", "19900101", "23709354", "24004576", "27201382", "31900543", "32402049", "32502647", "44404928", "67800652", "68600483", "72606041", "77001082", "217600253", "500031833", "501523903", "503392346", "504450120", "505935283", "506408584", "506672906", "508035217", "510849527", "512078507", "512930451", "515116258", "515772011", "516423668", "517656034", "523260804", "523680072", "529385152", "529767396", "530761351", "531021788", "535022497", "539825468", "543612099", "544881151", "545678688", "546492587", "546542494", "546567064", "546572064", "546631962", "546690648", "547091873", "547098754", "547177528", "547187391", "547272532", "548430564", "549195732", "550827394", "554061179", "554407734", "558377300", "565240108", "565859853", "566189037", "566664300", "569265917", "572521995", "572956856", "573953756", "574953924", "580937949", "589860486", "590245157", "590940415", "591070603", "594160450", "594274171", "594452024", "603927580", "605520271", "606541139", "610604803", "610978642", "618042063", "619680540", "624845905", "628235176", "628976871", "629730750", "629820318", "629960217", "642175690", "643298081", "659752530", "664598837", "666112048", "684786997", "686280655", "688007999", "689596293", "698640330", "699393049", "703427587", "705063052", "707765263", "711951229", "712743335", "713240181", "715882796", "720350220", "720886950", "731347173", "742596203", "743369432", "751377782", "756051583", "761010312", "763045077", "764619434", "768184036", "777725173", "778870130", "780624163", "789287731", "794495829", "794671958", "821640386", "829932247", "843615575", "845320400", "847735037", "883200586", "1006483796", "1007143495", "1008514568", "1020813223", "1031074695", "1037187187", "1041450082", "1041510153", "1055790362", "1056240014", "1059468090", "1083946504", "1153131614", "1157346411", "1171782424", "1224771465", "1276494059", "1294779053", "1316730161", "1364641590", "1393300306", "1397027770", "1433341178", "1452930023", "1491100934", "1524000010", "1543103529", "1553881511", "1556625823", "1636489309", "1640227273", "1653886798", "1682880020", "1682880037", "1682880038", "1746680919", "1772072139", "1846550208", "100000049912171", "100000098807776", "100000160899544", "100000257177602", "100000353950542", "100000452740095", "100000480064561", "100000500324298", "100000631459780", "100000721817834", "100001152622932", "100001158537314", "100001483789469", "100001493170272"];
      end

      if facebook_id.nil? then
        facebook_id = @@peter_id
      end

      puts "find checkins for facebook_id_array: #{facebook_id_array} with token: #{self.access_token}"
      
      self.update_fetch_progress(facebook_id, 0.1) # force progress to 0
    
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['fields'] = 'id,from,tags,place,message,application,created_time'
      if since then
        u = User.find_by_facebook_id(facebook_id)
        if not u.last_fetched_checkins.nil? then
          params_hash['since'] = u.last_fetched_checkins.to_i
        end
      end

      # progress indicator
      num_friends = facebook_id_array.count
      num_friends_serialized = 0
      
      self.update_fetch_progress(facebook_id, 0.25) # set the progress to 25%

      place_id_array = Array.new

      facebook_id_array.each do |friend_id|
        # Each person has a different last_fetched_checkins timestamp
        # u = User.find_by_facebook_id(facebook_id)
        # if not u.last_fetched_checkins.nil? then
        #  params_hash['since'] = u.last_fetched_checkins.to_i
        # end

        r = Typhoeus::Request.new("#{@@fb_host}/#{friend_id}/checkins", :method => :get, :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

        # Run this block when the request completes
        r.on_complete do |response|
          puts "Request complete for friend checkins with friend_id: #{friend_id}"
          num_friends_serialized += 1
          puts "Printing body: #{response.body}"
          puts "Resposne code: #{response.code}"
          parsed_response = self.parse_json(response.body)

          # Parse checkins
          parsed_response['data'].each do |checkin|
            self.serialize_checkin(checkin)
            place_id_array << checkin['place']['id']
          end

          puts "\n\n\n\n======#{friend_id}======\n\n\n\n"

          # last fetched checkins only works for the current user
          # self.update_last_fetched_checkins(friend_id) # Update last_fetched_checkins timestamp for user
          
          self.update_fetch_progress(facebook_id, ((num_friends_serialized.to_f / num_friends.to_f) / 2) + 0.25)
        end

        self.hydra.queue r # add the request to the queue
      end

      self.hydra.run # blocking call to run the queue

      # Serialize unique list of place_ids
      if !place_id_array.empty?
        self.find_places_for_place_id_array_batch(place_id_array.uniq)
      end

      # Force update progress to 100%
      self.update_fetch_progress(facebook_id, 1.0)

    end

    # Finds all checkins for an array of user ids
    # https://graph.facebook.com/checkins?ids=4804606,548430564,645750651&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def find_checkins_for_facebook_id_array(facebook_id = nil, facebook_id_array = nil, since = false)
      if facebook_id_array.nil? then
        facebook_id_array = [@@peter_id, @@tom_id, @@james_id]
        # facebook_id_array = ["102167", "107491", "202402", "202451", "206635", "210258", "221423", "222383", "223314", "300994", "404120", "407230", "837181", "1203891", "1204271", "1205313", "1206669", "1207467", "1209924", "1212462", "1214835", "1215870", "1217270", "1217767", "1218796", "1229612", "1237074", "1302698", "2203609", "2414683", "2420700", "2502195", "2502827", "2504814", "2539351", "2602152", "3001631", "3200308", "3200338", "3200785", "3201209", "3207713", "3213585", "3213871", "3213930", "3215015", "3223008", "3224819", "3225115", "3225501", "3302615", "3307216", "3308028", "3312026", "3318595", "3323295", "3400229", "3407534", "3409627", "3414242", "3430753", "3619557", "4804600", "4804606", "4804969", "4805917", "4807345", "4809933", "5505430", "6002685", "6006398", "6010421", "6817010", "7903099", "8620430", "8621075", "8639036", "10703701", "10710317", "10717536", "10718558", "10723087", "10729766", "10731869", "12438683", "12803642", "12805273", "12822783", "13004004", "13704812", "14900845", "67800652", "68600483", "77001082", "500031833", "500676063", "501591312", "503265413", "506408584", "510849527", "543612099", "547177528", "558377300", "573953756", "589860486", "590245157", "591070603", "593399035", "610978642", "624067894", "628447811", "629960217", "645750651", "666112048", "705063052", "707267501", "712743335", "720886950", "745245646", "745938780", "780624163", "802745284", "817333087", "847735037", "883200586", "1008514568", "1017673909", "1059468090", "1067580021", "1099524954", "1121490493", "1155635614", "1184055409", "1224771465", "1316730161", "1321571526", "1483053421", "1653886798", "100000049912171", "100000199684521", "100000576881557", "100000721817834", "100001483789469", "100001893113244"]
        # facebook_id_array = ["8963", "15500", "102167", "107491", "113140", "124718", "200408", "202451", "206635", "221423", "223984", "300994", "304753", "404120", "407230", "602380", "602908", "700411", "700640", "700913", "804962", "806533", "902398", "907578", "926017", "1104245", "1204213", "1205313", "1207135", "1209345", "1215870", "1217270", "1217767", "1232357", "1237074", "1238132", "1302148", "1302698", "1305225", "1317243", "1500280", "1503126", "1602207", "1900323", "1901630", "1946902", "2203649", "2204941", "2205136", "2260313", "2404878", "2420700", "2502195", "2502827", "2504814", "2511909", "2519703", "2520511", "2535681", "2535961", "2539351", "2602139", "2602152", "3001341", "3001631", "3102907", "3207046", "3207713", "3213871", "3214263", "3223008", "3225501", "3309147", "3312630", "3313694", "3318595", "3400229", "3405555", "3407534", "3409627", "3414242", "3422207", "3430753", "3431548", "3500262", "3601361", "3624841", "4200185", "4800419", "4800558", "4801645", "4801649", "4804600", "4804606", "4805917", "4807345", "4809933", "5311725", "5400602", "5401293", "5404625", "5505430", "5722387", "6000997", "6001293", "6002470", "6006398", "6006769", "6006817", "6007206", "6009423", "6010195", "6010421", "6013940", "6020556", "6029659", "6101740", "6103147", "6313486", "6403474", "6817010", "7903099", "7906450", "7944583", "8106362", "8504876", "8620430", "8621075", "8639036", "8819965", "9001569", "9219543", "9300454", "9351864", "10500882", "10701381", "10703701", "10703965", "10705786", "10706085", "10706823", "10707429", "10707911", "10708143", "10708824", "10710317", "10710655", "10712133", "10713943", "10714527", "10717536", "10718558", "10723087", "10723888", "10724566", "10727107", "10729538", "10729766", "10731869", "10732097", "10734785", "11509277", "11710692", "12409925", "12438683", "12801350", "12801778", "12803642", "12804385", "12805273", "12822783", "13004004", "13300908", "13309538", "13601113", "13704812", "13705330", "13710035", "13727874", "13748822", "14900845", "15100199", "15102941", "16103897", "16910989", "19900101", "23709354", "24004576", "27201382", "31900543", "32402049", "32502647", "44404928", "67800652", "68600483", "72606041", "77001082", "217600253", "500031833", "501523903", "503392346", "504450120", "505935283", "506408584", "506672906", "508035217", "510849527", "512078507", "512930451", "515116258", "515772011", "516423668", "517656034", "523260804", "523680072", "529385152", "529767396", "530761351", "531021788", "535022497", "539825468", "543612099", "544881151", "545678688", "546492587", "546542494", "546567064", "546572064", "546631962", "546690648", "547091873", "547098754", "547177528", "547187391", "547272532", "548430564", "549195732", "550827394", "554061179", "554407734", "558377300", "565240108", "565859853", "566189037", "566664300", "569265917", "572521995", "572956856", "573953756", "574953924", "580937949", "589860486", "590245157", "590940415", "591070603", "594160450", "594274171", "594452024", "603927580", "605520271", "606541139", "610604803", "610978642", "618042063", "619680540", "624845905", "628235176", "628976871", "629730750", "629820318", "629960217", "642175690", "643298081", "659752530", "664598837", "666112048", "684786997", "686280655", "688007999", "689596293", "698640330", "699393049", "703427587", "705063052", "707765263", "711951229", "712743335", "713240181", "715882796", "720350220", "720886950", "731347173", "742596203", "743369432", "751377782", "756051583", "761010312", "763045077", "764619434", "768184036", "777725173", "778870130", "780624163", "789287731", "794495829", "794671958", "821640386", "829932247", "843615575", "845320400", "847735037", "883200586", "1006483796", "1007143495", "1008514568", "1020813223", "1031074695", "1037187187", "1041450082", "1041510153", "1055790362", "1056240014", "1059468090", "1083946504", "1153131614", "1157346411", "1171782424", "1224771465", "1276494059", "1294779053", "1316730161", "1364641590", "1393300306", "1397027770", "1433341178", "1452930023", "1491100934", "1524000010", "1543103529", "1553881511", "1556625823", "1636489309", "1640227273", "1653886798", "1682880020", "1682880037", "1682880038", "1746680919", "1772072139", "1846550208", "100000049912171", "100000098807776", "100000160899544", "100000257177602", "100000353950542", "100000452740095", "100000480064561", "100000500324298", "100000631459780", "100000721817834", "100001152622932", "100001158537314", "100001483789469", "100001493170272"];
      end

      if facebook_id.nil? then
        facebook_id = @@peter_id
      end

      puts "find checkins for facebook_id_array: #{facebook_id_array} with token: #{self.access_token}"

      # OLD STYLE BATCHED
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['fields'] = 'id,from,tags,place,message,application,created_time'
      params_hash['ids'] = facebook_id_array.join(',')
      if since then
        u = User.find_by_facebook_id(facebook_id)
        if not u.last_fetched_checkins.nil? then
          params_hash['since'] = u.last_fetched_checkins.to_i
        end
      end

      # u = User.find_by_facebook_id(facebook_id)
      #  if not u.last_fetched_checkins.nil? then
      #    params_hash['since'] = u.last_fetched_checkins.to_i
      #  end
      #

      # progress indicator
      num_friends = facebook_id_array.count

      self.update_fetch_progress(facebook_id, 0.25) # set the progress to 25%


      response = Typhoeus::Request.get("#{@@fb_host}/checkins", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      puts "\n\n======\n\nPrinting raw response: #{response.body}\n\n=======\n\n"

      parsed_response = self.parse_json(response.body)

      # WE NEED TO HANDLE ERRORS
      # {"error"=>{"type"=>"OAuthException", "message"=>"(#613) Calls to checkin_fql have exceeded the rate of 600 calls per 600 seconds."}}
      # {"error_code":1,"error_msg":"An unknown error occurred"}

      # IF we get throttled, spawn a delayed_job and send it off after 10 minutes

      # puts "Printing body: #{response.body}"

      # puts "\n\n\n\n\nPARSED: #{parsed_response}\n\n\n\n\n"


      place_id_array = Array.new

      # Parse checkins for each user
      parsed_keys = parsed_response.keys

      parsed_keys.each_with_index do |key,i|
        parsed_response[key]['data'].each do |checkin|
          self.serialize_checkin(checkin)
          place_id_array << checkin['place']['id']
        end
        self.update_fetch_progress(facebook_id, ((i.to_f / num_friends.to_f) / 2) + 0.25) # update fetch progress percentage
      end

      # Serialize unique list of place_ids
      if !place_id_array.empty?
        self.find_places_for_place_id_array_batch(place_id_array.uniq)
      end

      # update last fetched checkins only works for the current user
      # Update last_fetched_checkins timestamp for all users
      # facebook_id_array.each do |facebook_id|
      #   self.update_last_fetched_checkins(facebook_id)
      # end

      # Force update progress to 100%
      self.update_fetch_progress(facebook_id, 1.0)

      # END OLD STYLE

    end

    # https://graph.facebook.com/search?type=checkin&access_token=ACCESS_TOKEN
    # def find_all_checkins
    #   begin
    #     headers_hash = Hash.new
    #     headers_hash['Accept'] = 'application/json'
    #
    #     params_hash = Hash.new
    #     params_hash['access_token'] = self.access_token
    #     params_hash['type'] = 'checkin'
    #     params_hash['limit'] = '50'
    #
    #     response = Typhoeus::Request.get("#{@@fb_host}/search", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
    #     p response.headers
    #     parsed_response = self.parse_json(response.body)
    #
    #     # Parse checkins
    #     parsed_response['data'].each do |checkin|
    #       self.serialize_checkin(checkin)
    #     end
    #   rescue => e
    #     p e.message
    #     p e.backtrace
    #     return false
    #   else
    #     return true
    #   end
    # end

    # https://graph.facebook.com/search?q=pizza&type=place&center=lat,long&distance=1000
    def find_places_near_location(lat = nil, lng = nil, distance = 1000, query = nil)
      # query is optional

      # debug
      if lat.nil? then lat = @@peter_latitude end
      if lng.nil? then lng = @@peter_longitude end

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['type'] = 'place'
      params_hash['center'] = "#{lat},#{lng}"
      params_hash['distance'] = "#{distance.to_i}" # safety force to integer because FBAPI wants int (no decimals)
      if not query.nil?
        params_hash['q'] = "#{query}"
      end

      response = Typhoeus::Request.get("#{@@fb_host}/search", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = self.parse_json(response.body)

      # Serialize Places
      parsed_response['data'].each do |place|
        self.serialize_place(place)
      end

      return parsed_response # temporarily just bypass proxy FB's response

    end

    # https://graph.facebook.com/121328401214612?access_token=2227470867%7C2.i5b1iBZNAy0qqtEfcMTGRg__.3600.1296727200-548430564%7Cxm3tEtVeLY9alHMAh-0Us17qpbg
    # API::FacebookApi.new.find_place_for_place_id(121328401214612)
    def find_place_for_place_id(place_id = nil)

      if place_id.nil? then place_id = 57167660895 end # cafe zoe

      puts "find places for place_id: #{place_id}"

      # fields to get
      # feed - all posts/comments on the page
      # photos - photos posted on the page
      # notes - not sure?
      # checkins - shows checkins from friends of current access_token

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      # params_hash['fields'] = 'feed,photos,notes,checkins'

      response = Typhoeus::Request.get("#{@@fb_host}/#{place_id}", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = self.parse_json(response.body)

      # Serialize Place
      facebook_place = self.serialize_place(parsed_response)

      return facebook_place

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
    
    # Find all places for an array of place_ids
    # https://graph.facebook.com/?ids=116154718413160,121328401214612,57167660895
    # API::FacebookApi.new.find_place_for_place_id_array([116154718413160,121328401214612,57167660895])
    def find_places_for_place_id_array(place_id_array = nil)

      if place_id_array.nil? then
        place_id_array = [121328401214612,57167660895] # cafe zoe
      end

      puts "find places for place_id_array: #{place_id_array}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['ids'] = place_id_array.join(',')

      response = Typhoeus::Request.get("#{@@fb_host}/", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = self.parse_json(response.body)

      # WE NEED TO HANDLE ERRORS
      # {"error"=>{"type"=>"OAuthException", "message"=>"(#613) Calls to checkin_fql have exceeded the rate of 600 calls per 600 seconds."}}

      # puts "\n\n\n\n\nPARSED: #{parsed_response}\n\n\n\n\n"

      # Parse places keys
      parsed_keys = parsed_response.keys

      parsed_keys.each do |key|
        # puts "#{key}"
        facebook_place = self.serialize_place(parsed_response[key])
      end

      # Update update_expires_at_place_id timestamp
      place_id_array.each do |place_id|
        self.update_expires_at_place_id(place_id)
      end


    end

    # Finds friends for a single facebook id
    # https://graph.facebook.com/me/friends?fields=third_party_id,first_name,last_name,name,gender,locale&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def find_friends_for_facebook_id(facebook_id = nil, since = false)

      if facebook_id.nil? then facebook_id = @@peter_id end

      puts "find friends for facebook_id: #{facebook_id}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'

      if since then
        u = User.find_by_facebook_id(facebook_id)
        if not u.last_fetched_friends.nil? then
          params_hash['since'] = u.last_fetched_friends.to_i
        end
      end


      response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}/friends", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = self.parse_json(response.body)

      friend_id_array = Array.new

      # Parse friends
      parsed_response['data'].each do |friend|
        friend_id_array << friend['id']
        self.serialize_user(friend)
        self.serialize_friend(friend, facebook_id, 1)
      end

      # Update last_fetched_friends timestamp for user
      self.update_last_fetched_friends(facebook_id)

      return friend_id_array

    end

    # Finds friends for an array of facebook ids
    # https://graph.facebook.com/friends?ids=4804606,548430564,645750651&fields=third_party_id,first_name,last_name,name,gender,locale&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def find_friends_for_facebook_id_array(facebook_id = nil, facebook_id_array = nil, since = false)
      
      if facebook_id.nil? then facebook_id = @@peter_id end
        
      if facebook_id_array.nil? then
        facebook_id_array = [@@peter_id, @@tom_id, @@james_id]
      end

      puts "find friends for facebook_id_array: #{facebook_id_array}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'
      params_hash['ids'] = facebook_id_array.join(',')
      if since then
        u = User.find_by_facebook_id(facebook_id)
        if not u.last_fetched_friends.nil? then
          params_hash['since'] = u.last_fetched_friends.to_i
        end
      end

      response = Typhoeus::Request.get("#{@@fb_host}/friends", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = self.parse_json(response.body)

      friend_id_array = Array.new

      # Parse friends for each user
      parsed_keys = parsed_response.keys
      parsed_keys.each do |key|
        friend_id_array << key # add friend to array
        parsed_response[key]['data'].each do |friend|
          self.serialize_user(friend)
          self.serialize_friend(friend, key.to_i, 1)
        end
      end

      return friend_id_array

    end

    def find_user_for_facebook_id(facebook_id = nil)

      if facebook_id.nil? then facebook_id = @@peter_id end

      puts "find user for facebook_id: #{facebook_id}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale,verified'

      response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = self.parse_json(response.body)

      # Parse user
      facebook_user = self.serialize_user(parsed_response)

      return facebook_user

    end

    def find_user_for_facebook_access_token

      puts "find user for access_token: #{self.access_token}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = self.access_token
      params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale,verified'

      response = Typhoeus::Request.get("#{@@fb_host}/me", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = self.parse_json(response.body)

      facebook_user = self.serialize_user(parsed_response, access_token)

      return facebook_user

    end

  end
end
