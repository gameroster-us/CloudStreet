# Sidekiq.configure_server do |config|
#   config.error_handlers << Proc.new do |ex,ctx_hash|
#     CSLogger.error "SIDEKIQ EXCEPTION: *********************************************************"
#     CSLogger.error ex.inspect
#     CSLogger.error ex.backtrace
#     CSLogger.info "*************************************************"
#   end
# end

require "sidekiq"
require 'sidekiq/api'
require "#{Rails.root}/lib/CS_logger"
require "#{Rails.root}/lib/CS_logger_formatter"

redis_config = Rails.application.config_for(:redis)

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{redis_config['host']}:#{redis_config['port']}/#{redis_config['db']}"}
end

Sidekiq::Extensions.enable_delay!

Sidekiq.logger = Logger.new("log/sidekiq.log") # [Rails.env] # Log4r::Logger.new 'sidekiq'
Sidekiq.logger.level = ActiveSupport::Logger::INFO
Sidekiq.logger.formatter = CSLoggerFormatter.new
Sidekiq.logger = ActiveSupport::TaggedLogging.new(Sidekiq.logger)

class SidekiqMiddleware
  def call(worker, msg, queue)
    worker.retry_count = msg['retry_count'] if worker.respond_to?(:retry_count)
    yield
  end
end

# require "objspace"
# ObjectSpace.trace_object_allocations_start
Sidekiq.logger.info "allocations tracing enabled"

module Sidekiq
  module Middleware
    module Server
      class Profiler
        # Number of jobs to process before reporting
        JOBS = 10

        class << self
          mattr_accessor :counter
          self.counter = 0

          def synchronize(&block)
            @lock ||= Mutex.new
            @lock.synchronize(&block)
          end
        end

        def call(worker_instance, item, queue)
          begin
            yield
          ensure
            self.class.synchronize do
              self.class.counter += 1

              if self.class.counter % JOBS == 0
                # Sidekiq.logger.info "reporting allocations after #{self.class.counter} jobs"
                GC.start
                # output = File.open("heap#{self.class.counter}.json", "w")
                # ObjectSpace.dump_all(output: output)
                # output.close
                # Sidekiq.logger.info "heap saved to heap.json"
              end
            end
          end
        end
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{redis_config['host']}:#{redis_config['port']}/#{redis_config['db']}"}
  config.super_fetch!
  config.reliable_scheduler!
  config.server_middleware do |chain|
    chain.add SidekiqMiddleware
    chain.add Sidekiq::Middleware::Server::Profiler
  end
end