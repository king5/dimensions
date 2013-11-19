Tire.configure do
  url APP_CONFIG['elasticsearch_api_url']
  logger Rails.root.join("log/#{Rails.env}.log"), :level => 'debug' if Rails.env.development?
end
