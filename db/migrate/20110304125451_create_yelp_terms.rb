class CreateYelpTerms < ActiveRecord::Migration
  def self.up
    create_table :yelp_terms do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :yelp_terms
  end
end
