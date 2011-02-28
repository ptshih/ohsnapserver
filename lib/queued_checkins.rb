class QueuedCheckins < Struct.new(:access_token, :facebook_id, :facebook_id_array, :since)
  # When to run procs
  def self.when_to_run_get_friends_checkins
    11.minutes.from_now
  end
  
  # Method Calls
  def get_friends_checkins_async
    facebook_api = API::FacebookApi.new(access_token)
    # Find checkins for current user and friends of the current user
    facebook_api.find_checkins_for_facebook_id_array(facebook_id, facebook_id_array, since)
  end
  handle_asynchronously :get_friends_checkins_async
  # handle_asynchronously :get_friends_checkins, :run_at => Proc.new { when_to_run_get_friends_checkins }
  
  
end