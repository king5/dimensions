class FeedUpdater
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  @queue = :feeds

  def self.perform
    NewsFeed.find_each do |feed|
      feed.update_entries
    end
  end
end
