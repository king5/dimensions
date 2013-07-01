class AddGeolocatizationForFeedEntries < ActiveRecord::Migration
  def up
    add_column :feed_entries, :latitude, :string
    add_column :feed_entries, :longitude, :string
  end

  def down
    remove_column :feed_entries, :latitude
    remove_column :feed_entries, :longitude
  end
end
