class CreatePlacePosts < ActiveRecord::Migration
  def self.up
    create_table :place_posts do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :place_posts
  end
end
