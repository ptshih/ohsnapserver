class CreateCheckinsPosts < ActiveRecord::Migration
  def self.up
    create_table :checkins_posts do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :checkins_posts
  end
end
