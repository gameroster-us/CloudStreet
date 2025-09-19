class ServerIdleWorker
  include Sidekiq::Worker
  sidekiq_options queue: :idle_service_queue, backtrace: true
   def perform(options)
      ServiceWiseIdleDataWorker.set(queue: options['worker_queue']).perform_async(options)
   end
end
