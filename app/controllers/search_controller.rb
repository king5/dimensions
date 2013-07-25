class SearchController < ApplicationController
  def index
    #build our main searcher tags or search text
    options = params
    owner=nil
    size = (params[:size]||25).to_i
    from = params["page"].to_i * size
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
      self.from from
      self.size size
      sort  do 
        by :social_ranking, { order: :desc, ignore_unmapped: true }
      end
    end

    facets = {}
    @search.facets.each{|k,v| facets[k]=v["terms"]} unless @search.facets.nil?
    #TODO: immplement pagination for results
    #@results = @search.results
    #@results.options[:per_page] = params[:len].to_i
    #@results.options[:page] = params[:page] || 1

    render json: { results: @search.json["hits"]["hits"].map{|x|x["_source"]["feed_entry"]}, facets: facets, page: from, matches: @search.results.total }

  end

  def article
    qu= {"query"=>{ "ids" => { "values" => params["ids"].split(",") } } }

    @results = Tire.search(APP_CONFIG['elasticsearch_index'],qu)
    r=@results.instance_variable_get(:@response)

    render :json=>{:results =>  r["hits"]["hits"]}
  end
end
