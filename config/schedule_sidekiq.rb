set :output, '/home/cloudstreet/api/log/whenever-sidekiq.log'
set :environment, ENV["RAILS_ENV"]
env :PATH, ENV['PATH']
env :CUSTOMERIO_SITE_ID, ENV['CUSTOMERIO_SITE_ID']
env :CUSTOMERIO_API_KEY, ENV['CUSTOMERIO_API_KEY']
env :DOCKER_SIDEKIQ, ENV['DOCKER_SIDEKIQ']

every 30.minutes do
  rake 'cloud_trail_event:execute_trail'
end
