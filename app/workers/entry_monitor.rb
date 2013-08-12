class EntryMonitor
  include Sidekiq::Worker
  sidekiq_options :queue => :reindex_entries, :retry => 1, :backtrace => true

  def perform
    NewsFeed.find_each do |feed|
      feed.bg_reindex_feed
    end
  end
end
