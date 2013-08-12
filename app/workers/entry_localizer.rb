class EntryLocalizer
  include Sidekiq::Worker
  sidekiq_options :queue => :entries, :retry => 1, :backtrace => true

  def perform(entry_id)
    entry = FeedEntry.find(entry_id)
    FeedEntry.localize(entry)
  end
end
