class SearchController < ApplicationController
  def index
    #build our main searcher tags or search text
    options = params
    owner=nil
    size = params[:len].to_i || 20
    page = params[:page].to_i || 1 
    #real search json
    @search = Tire.search(APP_CONFIG['elasticsearch_index']) do 
      query { string "name: #{ options[:q] }*" } unless options[:q].blank?

      filter :geo_bounding_box, location: { top_left: [options[:sw_long],options[:ne_lat] ], bottom_right: [options[:ne_long],options[:sw_lat]] } unless options[:sw_long].blank?

      filter :range,  created_at: { from: Time.at(CGI.unescape(options[:start_date]).to_i).strftime("%FT%TZ"), to: (Time.at(CGI.unescape(options[:end_date].to_i)).strftime("%FT%TZ") rescue DateTime.now.new_offset(0).strftime("%FT%TZ")) } unless options[:start_date].blank?

      facet 'tags' do
        terms :no_tag_body, size: 30
      end

      facet 'source_tags' do 
        terms :tag, size: 30
      end

      facet 'topics' do 
        terms :topics, size: 30
      end

      facet 'articles' do 
        date :created_at, interval: "hour"
      end
      self.from (page * size) - 20
      self.size size
      sort  do 
        by :social_ranking, { order: :desc, ignore_unmapped: true }
      end
    end

    facets = {}
    @search.facets.each{|k,v| facets[k]=v["terms"]} unless @search.facets.nil?
    render json: { results: @search.json["hits"]["hits"].map{|x|x["_source"]["feed_entry"]}, facets: facets, page: params[:page], matches: @search.results.total }
  end

  def article
    qu= {"query"=>{ "ids" => { "values" => params["ids"].split(",") } } }

    @results = Tire.search(APP_CONFIG['elasticsearch_index'],qu)
    r=@results.instance_variable_get(:@response)

    render :json=>{:results =>  r["hits"]["hits"]}
  end

end
