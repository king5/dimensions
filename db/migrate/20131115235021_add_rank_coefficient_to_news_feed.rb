class AddRankCoefficientToNewsFeed < ActiveRecord::Migration
  def up
    change_column :feed_entries, :rank_coefficient, :float, default: nil
    add_column :news_feeds, :rank_coefficient, :float, default: 1.8
  end

  def down
    remove_column :news_feeds, :rank_coefficient
    change_column :feed_entries, :rank_coefficient, :float, default: 1.8
  end
end
