class CleanIndexes
  include Sidekiq::Worker
  sidekiq_options :queue => :clean_index, :retry => 1, :backtrace => true
  
  def perform
    FeedEntry.remove_this_entries
  end

end
