class FeedUpdater
  include Sidekiq::Worker
  sidekiq_options :queue => :feeds, :retry => 1, :backtrace => true

  def perform
    NewsFeed.find_each do |feed|
      feed.update_entries
    end
  end
end
