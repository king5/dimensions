class ReindexFeed
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  @queue = :reindex_entries

  def self.perform(feed_id)
    NewsFeed.find(feed_id).reindex_feed
  end
end
