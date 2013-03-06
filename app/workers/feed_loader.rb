class FeedLoader
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  @queue = :feeds

  def self.perform(news_feed_id)
    news_feed = NewsFeed.find(news_feed_id)
    news_feed.load_entries
  end
end
