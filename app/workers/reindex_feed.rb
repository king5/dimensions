class ReindexFeed
  include Sidekiq::Worker
  sidekiq_options :queue => :reindex_entries, :retry => 1, :backtrace => true

  def perform(feed_id)
    NewsFeed.find(feed_id).reindex_feed
  end
end
