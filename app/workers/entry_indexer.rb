class EntryIndexer
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  @queue = :entries

  def self.perform(entry_id)
    index = Dimensions::SearchifyApi.instance.indexes(APP_CONFIG['searchify_index'])

    entry = FeedEntry.find(entry_id)
    entry.index_in_searchify(index)
  end
end
