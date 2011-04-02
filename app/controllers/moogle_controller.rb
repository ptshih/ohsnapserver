class MoogleController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  # Facebook Real Time Updates callback
  def fbcallback
    Rails.logger.info request.query_parameters.inspect
    
    # Check for GET
    if request.get? && params[:hub_mode] == 'subscribe' && params[:hub_verify_token] == 'omgwtfbbq'
      # Is a GET verification request
      return params[:hub_challenge]
    else
      # Is a POST subscription request
      parsed_json = JSON.parse(response.body)
      puts "fb response: #{parsed_json}"
    end
  end

  # Shows the ME timeline
  def kupos
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    # Query for condition where we're showing referrals (YouRF or FRYou ie You referred Friend or Friend referred You)
    # NOT USED FOR NOW
    # query = "select case when referMap.refer_direction='YouRF' then refer.created_time else referred.created_time end as sortColumn,
    #                         refer.checkin_id as you_checkin_id,
    #                         refer.created_time as you_created_time,
    #                         #{@current_user.facebook_id} as you_facebook_id,
    #                         'You' as you_name,
    #                         place.name as place_name,
    #                         place.place_id as place_id,
    #                         referred.checkin_id as checkin_id,
    #                         referred.created_time as created_time,
    #                         t.facebook_id as facebook_id,
    #                         t.name as name,
    #                         referMap.refer_direction
    #         from
    #         (select ref1.checkin_id as refer_checkin_id,
    #                 case when ref1.created_time<fr1.created_time then min(fr1.checkin_id) else max(fr1.checkin_id) end as checkin_id,
    #                 case when ref1.created_time<fr1.created_time then 'YouRF' else 'FRYou' end as refer_direction
    #         from checkins ref1
    #         join tagged_users ref2 on ref1.checkin_id = ref2.checkin_id and ref2.facebook_id = #{@current_user.facebook_id}
    #         join checkins fr1 on fr1.place_id  = ref1.place_id and ref1.created_time!=fr1.created_time
    #         join tagged_users fr2 on fr1.checkin_id = fr2.checkin_id
    #         where fr2.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
    #         group by 1 order by 1 desc) referMap
    #         join checkins refer on referMap.refer_checkin_id = refer.checkin_id
    #         join places place on place.place_id = refer.place_id
    #         join checkins referred on referMap.checkin_id = referred.checkin_id
    #         join tagged_users t on referred.checkin_id = t.checkin_id
    #         where t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
    #     order by 1 desc
    #     "    
    #     mysqlresults = ActiveRecord::Base.connection.execute(query)
    #     response_array = []
    #     while mysqlresult = mysqlresults.fetch_hash do
    #       if mysqlresult['refer_direction']=="YouRF"
    #         refer_hash = {
    #           :refer_checkin_id => mysqlresult['you_checkin_id'],
    #           :refer_created_time => Time.parse(mysqlresult['you_created_time'].to_s).to_i,
    #           :refer_facebook_id => mysqlresult['you_facebook_id'],
    #           :refer_name => mysqlresult['you_name'],
    #           :place_name => mysqlresult['place_name'],
    #           :place_id => mysqlresult['place_id'],
    #           :checkin_id => mysqlresult['checkin_id'],
    #           :created_time => Time.parse(mysqlresult['created_time'].to_s).to_i,
    #           :facebook_id => mysqlresult['facebook_id'],
    #           :name => mysqlresult['name']
    #         }
    #       else
    #         refer_hash = {
    #           :refer_checkin_id => mysqlresult['checkin_id'],
    #           :refer_created_time => Time.parse(mysqlresult['created_time'].to_s).to_i,
    #           :refer_facebook_id => mysqlresult['facebook_id'],
    #           :refer_name => mysqlresult['name'],
    #           :place_name => mysqlresult['place_name'],
    #           :place_id => mysqlresult['place_id'],
    #           :checkin_id => mysqlresult['you_checkin_id'],
    #           :created_time => Time.parse(mysqlresult['you_created_time'].to_s).to_i,
    #           :facebook_id => mysqlresult['you_facebook_id'],
    #           :name => mysqlresult['you_name']
    #         }        
    #       end
    #       response_array << refer_hash
    #     end
    #     mysqlresults.free
    
    # Paging parameter require time bounds and limit
    time_bounds = ""
    if params[:since]!=nil && params[:until]==nil
      time_bounds = " and c.created_time>from_unixtime(#{params[:since].to_i})"
    # pass until, then get everything < until
    elsif params[:since]==nil && params[:until]!=nil
      time_bounds = " and c.created_time<from_unixtime(#{params[:until].to_i})"
    else
    end
    limit_count = " limit 100"
    if !params[:count].nil?
      limit_count = " limit #{params[:count]}"
    end
    
    # Following places that you've checked-in to in the last month
    query = "select  p.place_id, p.name as place_name,
            you_t.facebook_id as your_facebook_id,
            c.created_time as checkin_time,
            t.facebook_id,
            t.name,
            max(you_c.created_time) as your_last_checkin_time
      from checkins you_c
      join tagged_users you_t on you_c.checkin_id = you_t.checkin_id and you_t.facebook_id = #{@current_user.facebook_id}
      join checkins c on you_c.place_id = c.place_id " + time_bounds + "
      join tagged_users t on c.checkin_id = t.checkin_id
          and (t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id}) or t.facebook_id = #{@current_user.facebook_id})
      join places p on p.place_id = c.place_id
      where you_c.created_time>=date_add(now(), interval - 1 month)
    group by 1,2,3,4,5,6
    order by 4 desc
    " + limit_count
    
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    response_array = []
    while mysqlresult = mysqlresults.fetch_hash do
      if mysqlresult['facebook_id']==mysqlresult['your_facebook_id'] && mysqlresult['your_last_checkin_time']==mysqlresult['checkin_time']
        #Ignore entries where your most recent checkin IS that actual checkin
      else
        refer_hash = {
          :checkin_time => Time.parse(mysqlresult['checkin_time'].to_s).to_i,
          :place_id => mysqlresult['place_id'],
          :place_name => mysqlresult['place_name'],
          :user_facebook_id => mysqlresult['facebook_id'],
          :user_name => mysqlresult['name'],
          :your_last_checkin_time => Time.parse(mysqlresult['your_last_checkin_time'].to_s).to_i,
          :your_facebook_id => mysqlresult['your_facebook_id']
        }
        response_array << refer_hash
      end
    end
    mysqlresults.free
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  
  end
  
end
