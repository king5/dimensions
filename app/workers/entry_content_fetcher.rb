class EntryContentFetcher
  include Sidekiq::Worker
  sidekiq_options :queue => :entries, :retry => 1, :backtrace => true

  def perform(entry_id)
    entry = FeedEntry.find_by_id(entry_id)
    entry.fetch
  end
end
