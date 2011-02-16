class FriendsCheckins < Struct.new(:facebook_api, :facebook_id, :facebook_id_array)
  
  def perform
    # Find checkins for current user and friends of the current user
    facebook_api.find_checkins_for_facebook_id_array(facebook_id, facebook_id_array)
  end
end