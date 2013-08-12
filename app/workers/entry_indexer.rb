class EntryIndexer
  include Sidekiq::Worker
  sidekiq_options :queue => :entries, :retry => 1, :backtrace => true

  def perform(entry_id)
    entry = FeedEntry.find(entry_id)
    entry.index_in_searchify
  end
end
