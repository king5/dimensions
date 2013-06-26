class Dimensions::ElasticsearchApi
  def initialize
  end
   
  @@instance ||= Tire
 
  def self.instance
    return @@instance
  end
 
  def index(index_name)
    @@instance::Index.new(index_name)
  end
 
  private_class_method :new
end

