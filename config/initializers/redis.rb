require 'connection_pool'

$redis = Redis.new(Rails.application.config_for(:redis))
REDIS = ConnectionPool.new(size: 200) { $redis }