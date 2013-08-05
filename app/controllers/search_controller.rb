class SearchController < ApplicationController
  def index
    #build our main searcher tags or search text
    options = params
    owner=nil
    size = params[:len].to_i || 20
    page = params[:page].to_i || 1 
    tags = params[:tags] || ""
    #real search json
    @search = Tire.search(APP_CONFIG['elasticsearch_index']) do 
      query { string "name: #{ options[:q] }*" } unless options[:q].blank?

      query do 
        boolean do
          should { string "tags.name:#{tags}" }
        end
      end unless tags.blank?

      filter :geo_bounding_box, location: { top_left: [options[:sw_long],options[:ne_lat] ], bottom_right: [options[:ne_long],options[:sw_lat]] } unless options[:sw_long].blank?

      filter :range,  created_at: { from: Time.at(CGI.unescape(options[:start_date]).to_i).strftime("%FT%TZ"), to: (Time.at(CGI.unescape(options[:end_date].to_i)).strftime("%FT%TZ") rescue DateTime.now.new_offset(0).strftime("%FT%TZ")) } unless options[:start_date].blank?

      self.from (page * size) - 20
      self.size size

      sort { by :social_ranking, 'desc' }
    end

    facets = {}
    @search.facets.each{|k,v| facets[k]=v["terms"]} unless @search.facets.nil?
    render json: { results: @search.json["hits"]["hits"].map{|x|x["_source"]["feed_entry"]}, facets: facets, page: params[:page], matches: @search.results.total }
  end

end
