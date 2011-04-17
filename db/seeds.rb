# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
# User.create(:name => 'Mosix Moog', :facebook_id => '100002020589088')
# User.create(:name => 'Bobby Mindflay', :facebook_id => '100002021759218')
# User.create(:name => 'Moone Moog', :facebook_id => '100002025298734')
# User.create(:name => 'Mofive Moog', :facebook_id => '100002026558846')
# User.create(:name => 'Mothree Moog', :facebook_id => '100002031089048')
# User.create(:name => 'Motwo Moog', :facebook_id => '100002039668743')
# User.create(:name => 'Mofour Moog', :facebook_id => '100002039968803')
# User.create(:name => 'Moeight Moog', :facebook_id => '100002045099120')
# User.create(:name => 'Naga Stolemybike', :facebook_id => '100002077440071')
# User.create(:name => 'Jim Raynor', :facebook_id => '100002079840056')
# User.create(:name => 'Phuc Datho', :facebook_id => '100002126850043')
# User.create(:name => 'Moseven Moog', :facebook_id => '100002030219173')
# User.create(:name => 'Monine Moog', :facebook_id => '100002046329197')
# User.create(:name => 'Biggie Smalls', :facebook_id => '100002117970046')

# Event(id: integer, tag: string, name: string, is_private: boolean, last_kupo_id: integer, last_loc_lat: decimal, last_loc_lng: decimal, created_at: datetime, updated_at: datetime) 
Event.create(:tag => '#lasvegas.1', :name => 'Las Vegas Party 2011', :is_private => false)
Event.create(:tag => '#verde.1', :name => 'Verde Tea Cafe', :is_private => false)
Event.create(:tag => '#jerryginawedding.1', :name => 'Jerry & Gina Wedding Seattle', :is_private => false)

