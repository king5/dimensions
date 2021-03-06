class EntryTagger
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  @queue = :entries

  def self.perform(entry_id)
    entry = FeedEntry.find(entry_id)
    FeedEntry.tag(entry)
  end
end
