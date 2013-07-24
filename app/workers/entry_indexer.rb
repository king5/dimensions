class EntryIndexer
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  @queue = :entries

  def self.perform(entry_id)
    entry = FeedEntry.find(entry_id)
    entry.index_in_searchify
  end
end
