class Article

end
require "pp"
class SearchController < ApplicationController
  def index
    #build our main searcher tags or search text
    options = params
    owner=nil
    size = (params[:size]||25).to_i
    from = params["page"].to_i * size
    #real search json
    @results = Tire.search(APP_CONFIG['elasticsearch_index']) do 
      query { string "name: #{ options[:q] }*", from: from , size: size, version: true } unless options[:q].blank?

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

      sort  do 
        by :created_at, :desc 
      end
    end

    facets = {}
    @results.facets.each{|k,v| facets[k]=v["terms"]} unless @results.facets.nil?

    render json: { results: @results.json["hits"]["hits"].map{|x|x["_source"]["feed_entry"]}, :facets => facets, page: from, total_results: @results.results.total }

  end

  def article
    qu= {"query"=>{ "ids" => { "values" => params["ids"].split(",") } } }

    @results = Tire.search(APP_CONFIG['elasticsearch_index'],qu)
    r=@results.instance_variable_get(:@response)

    render :json=>{:results =>  r["hits"]["hits"]}
  end
end
