require 'sidekiq'
require 'sidekiq-scheduler/client'
require 'sidekiq-scheduler/schedule'
require 'sidekiq-scheduler/worker'
require 'sidekiq-scheduler/version'
require 'sidekiq/scheduler'

rails_root = Rails.root || File.dirname(__FILE__) + '/../..'
rails_env = Rails.env || 'development'
resque_config = YAML.load_file(rails_root.to_s + '/config/resque.yml')

Sidekiq.configure_server do |config|
  config.redis = { :url => "redis://#{resque_config['development']}", :namespace => 'dimensions' }
  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
  end
end

Sidekiq.configure_client do |config|
  config.redis = { :url => "redis://#{resque_config['development']}", :namespace => 'dimensions' }
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end

Sidekiq.schedule = YAML.load_file(rails_root.to_s + '/config/sidekiq_scheduler.yml')
