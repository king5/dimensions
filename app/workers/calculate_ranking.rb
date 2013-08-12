class CalculateRanking
  include Sidekiq::Worker
  sidekiq_options :queue => :feed_entry, :retry => 1, :backtrace => true

  def perform(entry_id)
    entry = FeedEntry.find(entry_id)
    entry.update_facebook_stats
    entry.calculate_social_rank
    entry.re_index
  end
end
