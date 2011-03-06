class CreateCheckinsLikes < ActiveRecord::Migration
  def self.up
    create_table :checkins_likes do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :checkins_likes
  end
end
