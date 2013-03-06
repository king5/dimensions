class EntryContentFetcher
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  @queue = :entries

  def self.perform(entry_id)
    entry = FeedEntry.find_by_id(entry_id)
    entry.fetch
  end
end
