class FacebookCounter
  include Sidekiq::Worker
  sidekiq_options :queue => :feed_entry, :retry => 1, :backtrace => true

  def perform
    FeedEntry.to_recalculate.each do |entry|
      entry.bg_calculate_social_rank
    end
  end
end
