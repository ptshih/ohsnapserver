class CreateSharesMaps < ActiveRecord::Migration
  def self.up
    create_table :shares_maps do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :shares_maps
  end
end
