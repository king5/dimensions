class EntryLocalizer
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  @queue = :entries

  def self.perform(entry_id)
    entry = FeedEntry.find(entry_id)
    FeedEntry.localize(entry)
  end
end
