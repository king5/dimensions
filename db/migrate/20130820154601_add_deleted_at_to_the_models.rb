class AddDeletedAtToTheModels < ActiveRecord::Migration
  def up
    add_column :news_feeds, :deleted_at, :datetime
    add_column :feed_entries, :deleted_at, :datetime
    add_column :entities, :deleted_at, :datetime
  end

  def down
    remove_column :news_feeds, :deleted_at
    remove_column :feed_entries, :deleted_at
    remove_column :entities, :deleted_at
  end
end
