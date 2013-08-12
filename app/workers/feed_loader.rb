class FeedLoader
  include Sidekiq::Worker
  sidekiq_options :queue => :feeds, :retry => 1, :backtrace => true

  def perform(news_feed_id)
    news_feed = NewsFeed.find(news_feed_id)
    news_feed.load_entries
  end
end
