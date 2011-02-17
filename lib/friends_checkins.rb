class FriendsCheckins < Struct.new(:facebook_api, :facebook_id, :facebook_id_array, :since)
  
  def perform
    # Find checkins for current user and friends of the current user
    facebook_api.find_checkins_for_facebook_id_array_batch(facebook_id, facebook_id_array, since)
  end
end