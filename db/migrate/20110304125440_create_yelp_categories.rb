class CreateYelpCategories < ActiveRecord::Migration
  def self.up
    create_table :yelp_categories do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :yelp_categories
  end
end
