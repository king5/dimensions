(function($){

  $namespace('ElasticSearch').Client = function(){};

  $namespace('ElasticSearch').Client.prototype = {
    search: function(options){
      self = this;
      var  apiUrl =  $('#rails_api_config').data('api-url')
      var rootPath = $('#rails_to_js_config').data('root-path');
      var settings = $.extend({}, options || {});

      var result = undefined;

      $.ajax({
        url: rootPath +'/search',
        dataType: "json",
        type: "POST",
        success: function(data){
          self.onSearchSuccess(data);
        }
      });
    },
    bind: function(name, fn){
      ElasticSearch.Client.method(name, fn);
    },
    unbind: function(name, fn){
      ElasticSearch.Client.method(name, nil);
    }

  }
})(jQuery)
