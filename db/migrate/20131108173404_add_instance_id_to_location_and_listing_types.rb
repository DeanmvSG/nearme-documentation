class AddInstanceIdToLocationAndListingTypes < ActiveRecord::Migration
  def change
    add_column :listing_types, :instance_id, :integer
    add_index :listing_types, :instance_id
    add_column :location_types, :instance_id, :integer
    add_index :location_types, :instance_id
  end
end
