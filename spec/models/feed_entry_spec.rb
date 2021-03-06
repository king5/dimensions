require 'spec_helper'

describe FeedEntry, 'errors' do
  it 'should not be cleaned if failed' do
    feed_entry = FactoryGirl.build :feed_entry, fetch_errors: 'whatever', failed: true
    feed_entry.save
    feed_entry.reload
    feed_entry.fetch_errors.should == 'whatever'
  end

  it 'should be cleaned if not failed before save' do
    feed_entry = FactoryGirl.build :feed_entry, fetch_errors: 'whatever', failed: false, indexed: true
    feed_entry.save
    feed_entry.reload
    feed_entry.fetch_errors.should be_nil
  end

  it 'should be cleaned if indexed before save' do
    feed_entry = FactoryGirl.build :feed_entry, fetch_errors: 'whatever', failed: false, indexed: true
    feed_entry.save
    feed_entry.fetch_errors.should be_nil
  end
end
describe FeedEntry, '#index_in_searchify' do

  let(:index) do
    indexer = double(:indexer)
    indexer.stub_chain(:document, :add){true}
    indexer
  end

  let(:feed_entry) { FactoryGirl.create(:feed_entry, entities: [location]) }

  context 'with latitude and logitude given' do
    let!(:location) { FactoryGirl.create :entity, serialized_data: { 'latitude' => 123, 'longitude' => 123 } }

    before do
      feed_entry.primary_location = location
    end

    it 'should not fail' do
      feed_entry.index_in_searchify(index).should be_true
      feed_entry.failed.should be_false
      feed_entry.indexed.should be_true
    end

    it 'should fail if there is an Index Tank error' do
      index.stub_chain(:document, :add).and_raise IndexTank::UnexpectedHTTPException
      feed_entry.index_in_searchify(index).should be_false
      feed_entry.failed.should be_true
      feed_entry.indexed.should be_false
    end
  end

  context 'with no latitude given' do
    let!(:location) { FactoryGirl.create :entity, serialized_data: { 'longitude' => 123 } }

    before do
      feed_entry.primary_location = location
    end

    it 'should fail' do
      feed_entry.index_in_searchify(index).should be_false
      feed_entry.failed.should be_true
      feed_entry.indexed.should be_false
    end
  end

  context 'with no longitude given' do
    let!(:location) { FactoryGirl.create :entity, serialized_data: { 'latitude' => 123 } }

    before do
      feed_entry.primary_location = location
    end

    it 'should fail' do
      feed_entry.index_in_searchify(index).should be_false
      feed_entry.failed.should be_true
      feed_entry.indexed.should be_false
    end
  end
end

describe FeedEntry, 'entry.bg_calculate_social_rank' do
  it 'should enqueue CalculateRanking when instance method is called' do
    @entry = FactoryGirl.build(:feed_entry)
    @entry.bg_calculate_social_rank.should be_true
  end
end

describe FeedEntry, '.update_facebook_stats' do
  let!(:feed_entry) do
    FactoryGirl.create(
      :feed_entry,
      facebook_likes: 0,
      facebook_shares: 0,
      facebook_comments: 0
    )
  end

  let!(:facebook_response) do
    {
      'like_count' => 1,
      'share_count' => 1,
      'comment_count' => 1
    }
  end

  it 'updates facebook counts from Koala' do
    Koala::Facebook::API.any_instance.stub_chain(:fql_query, :first).and_return facebook_response
    feed_entry.update_facebook_stats
    feed_entry.facebook_likes.should == 1
    feed_entry.facebook_shares.should == 1
    feed_entry.facebook_comments.should == 1
  end

  it 'does not update on a network error' do
    Koala::Facebook::API.any_instance.stub(:fql_query).and_raise(Koala::Facebook::APIError)
    feed_entry.update_facebook_stats
    feed_entry.facebook_likes.should == 0
    feed_entry.facebook_shares.should == 0
    feed_entry.facebook_comments.should == 0
    feed_entry.failed.should == true
  end
end
describe FeedEntry do
  #******************** SCOPES********************
  describe ".failed" do
    before do
      @entry1 = FactoryGirl.create(:feed_entry, :failed => false)
      @entry2 = FactoryGirl.create(:feed_entry, :failed => true)
    end

    it "should return only feed entries without errors when passed false" do
      results = FeedEntry.failed(false)
      results.should include(@entry1)
      results.should_not include(@entry2)
    end
    it "should return only feed entries with errors when passed true" do
      results = FeedEntry.failed(true)
      results.should include(@entry2)
      results.should_not include(@entry1)
    end
  end

  #******************** CLASS METHODS********************

  describe "self.add_entries" do
    it 'converts feedzirra entries to feed_entry objects' do
      mock_entries = [
        mock( title: "The first post",
             summary: 'I was so lazy to write my first post',
             url: '/some-url-x',
             published: Time.now,
             id: '/my-unique-id',
             author: 'Inaki',
             content: 'blah blah'),
        mock( title: "The second post",
             summary: 'I was so lazy but now I\'m not',
             url: '/some-other-url',
             published: Time.now,
             id: '/my-other-unique-id',
             author: 'Inaki',
             content: 'blah, blah, blah')]
      news_feed = FactoryGirl.create(:news_feed)

      results = nil
      lambda{
        results = news_feed.add_entries(mock_entries)
      }.should change(FeedEntry, :count).by(2)

      news_feed.entries.count.should == 2
      results.count.should == 2
      results.map(&:name) =~ ['The first post', 'The second post']
      results.map(&:author).should =~ ['Inaki', 'Inaki']
    end
  end

  #describe 'self.add_tweet(urls)' do
    #entry = FactoryGirl.create(:feed_entry, :url => "http://slog.thestranger.com/slog/archives/2012/07/03/why-are-american-kids-so-spoiled")
    #tweet_urls = [{:indices=>[43, 63],
                    #:url=>"http://t.co/I2ndodld",
                    #:expanded_url=>
                   #"http://slog.thestranger.com/slog/archives/2012/07/03/why-are-american-kids-so-spoiled",
                   #:display_url=>"slog.thestranger.com/slog/archives/?"}]

    ##entry = FeedEntry.where(:url => "http://slog.thestranger.com/slog/archives/2012/07/03/why-are-american-kids-so-spoiled")
    ##FeedEntry.add_tweet(tweet_urls)
    ##expect{FeedEntry.add_tweet(tweet_urls)}.to change{entry.tweet_count}.by(1)
    #entry.tweet_count.should == 0
    #FeedEntry.add_tweet(tweet_urls)
    #entry.tweet_count.should == 1
  #end

  describe 'self.save_feedzirra_response' do
    it "creates a new feedzirra response" do
      news_feed_id = 1
      feed = mock
      response = mock
      response.should_receive(:save){true}
      FeedzirraResponse.should_receive(:new).with(:serialized_response => {news_feed_id => feed}, :news_feed_id => news_feed_id){response}
      FeedEntry.save_feedzirra_response(news_feed_id, feed)
    end
  end

  describe ".update_from_feed" do
    it 'should raise an exception when the feed is not valid' do
      Feedzirra::Feed.stub(:fetch_and_parse){nil}
      lambda {
        FeedEntry.update_from_feed('invalid url')
      }.should be_true
    end

    it 'should create entries whenever the feed --> feeds :p' do
      now = Time.zone.now

      feed = mock(:entries => ['Hola'], :etag => 'xyz', :last_modified => now)
      Feedzirra::Feed.stub(:fetch_and_parse){feed}

      news_feed = FactoryGirl.create(:news_feed, :url => 'http://king5.com')

      NewsFeed.stub(:find_by_url).with(news_feed.url){ news_feed }
      news_feed.should_receive(:add_entries).with(feed.entries){['Hola', 'Mundo']}

      entries = FeedEntry.update_from_feed(news_feed.url)

      news = NewsFeed.find(news_feed.id)
      news.etag.should  == 'xyz'
      #news.last_modified.should == now.to_s

      entries.should =~ ['Hola', 'Mundo']
    end
  end

  describe ".update_from_feed_continously" do
    context 'the url does not belong to any existing news feed' do
      it 'should raise an error' do
        news_feed = FactoryGirl.create(:news_feed, :url => 'http://king5.com')
        lambda{
          FeedEntry.update_from_feed_continuously('non-existing-url')
        }.should raise_error 'Couldn\'t find news feed with the given url'
      end
    end

    context 'the url belongs to a news feed' do
      before do
        @now = Time.now
        @news_feed  = FactoryGirl.create(:news_feed, :url => 'http://king5.com', :etag => 'xyz', :last_modified => @now)
        @feed_entry = FactoryGirl.create(:feed_entry, :feed => @news_feed)
      end

      context 'the feedzirra feed is not updated' do
        it 'should return without updating the news feed etag and last modified' do
          updated_feed = mock(:updated? => false)
          Feedzirra::Feed.stub(:update){updated_feed}

          FeedEntry.update_from_feed_continuously('http://king5.com')
          
          @news_feed.reload.etag.should == 'xyz'
          #@news_feed.reload.last_modified.should == @now
        end
      end

      context 'the feedzirra feed is updated' do
        before do
          @some_new_date = 2.days.since(Time.now)
          @updated_feed = mock(
            :updated? => true,
            :new_entries => ['an entry'],
            :etag => 'abc',
            :last_modified => @some_new_date
          )
          Feedzirra::Feed.stub(:update){@updated_feed}
          @news_feed.should_receive(:add_entries).with(['an entry'])
          NewsFeed.stub(:find_by_url).with(@news_feed.url){ @news_feed }
        end

        it 'should update the news feed etag and last modified' do
          FeedEntry.update_from_feed_continuously('http://king5.com')

          @news_feed.reload.etag.should == 'abc'
          @news_feed.reload.last_modified.should be_within(1).of(@some_new_date)
        end
      end
    end
  end

  describe "self.localize" do
    context "unfetched entry" do
      it "should return false" do
        @entry = mock_model(FeedEntry)
        @entry.stub(:fetched?){false}
        FeedEntry.localize(@entry).should be_false
      end
    end

    context "when the entry belongs to a localized newsfeed" do
      before do
        @feed_entry               = FactoryGirl.create(:feed_entry)
        @feed_entry.feed          = FactoryGirl.create(:news_feed, :name => "The Washington Post", :url => "http://thewashingtonpost.com")
        @feed_entry.feed.entities << FactoryGirl.create(:entity, :type => 'location', :serialized_data => {'longitude' => '1.0', 'latitude' => '2.0'})
        @feed_entry.feed.save
      end

      context "and the localization has not been successful" do
        before do
          @feed_entry.stub(:fetched?){true}
          @feed_entry.stub(:content){"some content"}

          calais_proxy = mock
          calais_proxy.stub(:doc_date){now}
          calais_proxy.stub_chain(:geographies){[]}
          Calais.stub(:process_document).with(:content => "some content", :content_type => :raw, :license_id => APP_CONFIG['open_calais_api_key'] ){calais_proxy}
          @feed_entry.stub(:primary_location=).with(@feed_entry.feed.location){true}
        end

        it "should get the localization of the news feed" do
          lambda{
            FeedEntry.localize(@feed_entry).should be_true
          }.should change(Entity, :count).by(0)

          feed_entry = FeedEntry.find(@feed_entry.id)

          locations_map = feed_entry.entities.location.map do|location|
            coordinates = location.serialized_data
            [location.name, coordinates['longitude'], coordinates['latitude']]
          end
          
          location = @feed_entry.feed.location 
          locations_map.should include([location.name, location.serialized_data['longitude'], location.serialized_data['latitude']])
        end
      end
    end

    context 'successfully localizing the entry' do

      before do
        @entry               = FactoryGirl.create(:feed_entry, :published_at => nil)
        @entry.feed          = FactoryGirl.create(:news_feed, :name => "The Washington Post", :url => "http://thewashingtonpost.com")
        @entry.feed.entities << FactoryGirl.create(:entity, :type => 'location', :serialized_data => {'longitude' => '1.0', 'latitude' => '2.0'})
        @entry.feed.save
      end

      it "should return true and must save the new localization" do
        @entry.stub(:fetched?){true}
        @entry.stub(:content){"some content"}

        calais_proxy = mock

        now = Time.zone.now
        calais_proxy.stub(:doc_date){now}

        calais_proxy.stub_chain(:geographies){["dummy"]}

        location = FactoryGirl.build(:entity, :type => 'location', :name => "Seattle" )
        Dimensions::Locator.stub(:parse_locations).with(calais_proxy.geographies){[location]}
        @feed_entry.stub(:primary_location=).with(location){true}

        Calais.stub(:process_document).with(:content => "some content", :content_type => :raw, :license_id => APP_CONFIG['open_calais_api_key'] ){calais_proxy}

        lambda{
          FeedEntry.localize(@entry).should be_true
        }.should change(Entity, :count).by(1)

        entry = FeedEntry.find(@entry.id)


        entry.published_at.should_not be_nil
        
        entity = entry.entities.where(:name => "Seattle").first
        entity.should_not be_nil
        entity.feed_entries.find(entry.id).should_not be_nil
      end
    end
  end

  describe "self.tag" do
    before do
      @entry = FactoryGirl.create(:feed_entry, content: 'mock content')
      @entry.stub(:localized?){true}

      calais_proxy = mock(categories: [mock(name: 'space')], entities: [mock(attributes: {'name' => 'NASA'}), mock(attributes: {'name' =>  'twitter'}), mock(attributes: {'name'  =>'von Braun'})])
      Calais.stub(:process_document).with(content: @entry.content, content_type: :raw, license_id: APP_CONFIG['open_calais_api_key'] ){calais_proxy}
    end

    it "should be assigned all tags found by open calais" do 
      FeedEntry.tag(@entry)
      entry = FeedEntry.find(@entry.id)
      entry.tags.count.should == 4

      entry.tags.map(&:name).should =~ ['space', 'NASA', 'twitter', 'von Braun']
    end
  end

  describe "#fetch content" do
    before do
      @entry = FactoryGirl.build(:feed_entry)
    end

    it "should return true if content is already there" do
      other_entry = FactoryGirl.create(:feed_entry)
      other_entry.content = "blah"
      other_entry.fetch_content!.should == "blah"
      EntryLocalizer.should have_queued(other_entry.id).in(:entries)
    end

    it "should fetch all the content existing between p tags in the requested url" do
      scraper = mock
      Scraper.stub(:define){ scraper }
      uri = mock
      URI.stub(:parse).with(@entry.url){uri}
      scraper.stub(:scrape).with(uri){
        ["Hola", "Mundo"]
      }
      @entry.fetch_content!.should == "Hola Mundo"
      @entry.content.should == "Hola Mundo"
      FeedEntry.find(@entry.id).content.should == "Hola Mundo"
      EntryLocalizer.should have_queued(@entry.id).in(:entries)
    end

    context "failure to fetch content" do
      it "should rescue the exception and add this to serialized fetch errors" do
        scraper = mock
        Scraper.stub(:define){ scraper }

        uri = mock
        URI.stub(:parse).with(@entry.url){uri}

        scraper.should_receive(:scrape).with(uri).and_raise(Scraper::Reader::HTMLParseError)
        @entry.fetch_content!.should be_nil
        @entry.fetch_errors.should == {:error => "Scraper::Reader::HTMLParseError"}
        @entry.failed?.should be_true
        FeedEntry.find(@entry.id).failed?.should be_true
      end
    end
  end

  describe 'locations' do
    context "when the entry has no locations at all" do
      it 'should return an empty array' do
        @feed_entry = FactoryGirl.create(:feed_entry)
        @feed_entry.locations.should == []
      end
    end

    context "when the entry has locations" do
      it 'should return them' do
        @feed_entry   = FactoryGirl.create(:feed_entry)
        location_1    = FactoryGirl.build(:entity, :name => 'GDL', :type => 'location')
        location_2    = FactoryGirl.build(:entity, :name => 'Manzanillo', :type => 'location')
        person        = FactoryGirl.build(:entity, :name => 'Jaime', :type => 'person')
        @feed_entry.entities << location_1
        @feed_entry.entities << location_2
        @feed_entry.entities << person

        results = @feed_entry.locations
        results.should include(location_1)
        results.should include(location_2)
        results.should_not include(person)
      end
    end

  end

  describe 'primary_location' do

    context "when the entry has no locations at all" do
      it 'should return nil' do
        @feed_entry = FactoryGirl.create(:feed_entry)
        @feed_entry.primary_location.should  be_nil
      end
    end

    context "when the entry has locations" do
      it 'should return only the one marked as primary' do
        @feed_entry   = FactoryGirl.create(:feed_entry)
        location_1    = FactoryGirl.build(:entity, :name => 'GDL', :type => 'location')
        location_2    = FactoryGirl.build(:entity, :name => 'Manzanillo', :type => 'location')

        @feed_entry.entities << location_1
        @feed_entry.entities << location_2

        @feed_entry.primary_location = location_1

        @feed_entry.primary_location.should == location_1
      end

      it "should return the last location marked as primary" do
        @feed_entry   = FactoryGirl.create(:feed_entry)
        location_1    = FactoryGirl.build(:entity, :name => 'GDL', :type => 'location')
        location_2    = FactoryGirl.build(:entity, :name => 'Manzanillo', :type => 'location')

        @feed_entry.entities << location_1
        @feed_entry.entities << location_2

        @feed_entry.primary_location = location_1
        @feed_entry.primary_location = location_2



        @feed_entry.primary_location.should == location_2
        @feed_entry.secondary_locations.should == [location_1]

      end
    end

    
    it "should be independent for each entry and unique" do
      entry   = FactoryGirl.create(:feed_entry)
      entry2  = FactoryGirl.create(:feed_entry)

      locations = [ FactoryGirl.build(:entity, :name => 'GDL', :type => 'location'),
                    FactoryGirl.build(:entity, :name => 'Manzanillo', :type => 'location')]

      entry.entities  = locations
      entry2.entities = locations

      guadalajara = entry.locations.find_by_name('GDL')
      entry.primary_location = guadalajara

      manzanillo  = entry2.locations.find_by_name('Manzanillo')
      entry2.primary_location = manzanillo
      
      entry.primary_location.should  == guadalajara
      entry2.primary_location.should == manzanillo
    end
  end

  describe 'secondary_locations' do
    context "when the entry has no locations at all" do
      it 'should return empty array' do
        @feed_entry = FactoryGirl.create(:feed_entry)
        @feed_entry.secondary_locations.should  be_empty
      end
    end

    context "when the entry has locations" do
      it 'should return the array of the secondary locations' do
        @feed_entry   = FactoryGirl.create(:feed_entry)
        
        location_1    = FactoryGirl.build(:entity, :name => 'GDL', :type => 'location')
        location_2    = FactoryGirl.build(:entity, :name => 'Manzanillo')

        @feed_entry.entities << location_1
        @feed_entry.entities << location_2

        @feed_entry.primary_location = location_1
        @feed_entry.secondary_locations.should == [location_2]
      end
    end
  end

  # -------- State machine tests --------
  describe "change state" do
    before do
      @entry = FactoryGirl.build(:feed_entry)
    end
    
    it "should initialize with :loaded" do
      @entry.new?.should == true
    end
    
    it "should get valid states when :fetch, :localize, and :tag" do
      @entry.download
      @entry.downloaded?.should be_true
      @entry.fetch
      @entry.fetched?.should == true
      @entry.localize
      @entry.localized?.should == true
      @entry.tag
      @entry.tagged?.should == true
    end

    describe 'after download' do
      before do
        ResqueSpec.reset!
      end

      it 'should enque the entry to be fetched' do
        @entry.download
        EntryContentFetcher.should have_queued(@entry.id).in(:entries)
      end
    end

    describe 'after localize' do
      before do
        ResqueSpec.reset!
      end

      it 'should enque the entry to be fetched' do
        @entry.update_attribute(:state, 'fetched')
        @entry.localize
        EntryTagger.should have_queued(@entry.id).in(:entries)
      end
    end

    describe 'after tagging' do
      before do
        ResqueSpec.reset!
      end

      it 'should enque the entry to be fetched' do
        @entry.update_attribute(:state, 'localized')
        @entry.tag
        EntryIndexer.should have_queued(@entry.id).in(:entries)
      end
    end
  end
end
