class FriendsCheckins < Struct.new(:access_token, :facebook_id, :facebook_id_array, :since)
  def perform
    facebook_api = API::FacebookApi.new(access_token)
    # Find checkins for current user and friends of the current user
    facebook_api.find_checkins_for_facebook_id_array_batch(facebook_id, facebook_id_array, since)
  end
end