class Azure::Idle::VirtualMachineIdleWorker

  include Sidekiq::Worker
  sidekiq_options queue: :azure_idle_queue, backtrace: true

  def perform(options)
    if options['queue_name'].present?
      batch.jobs { Azure::Idle::ServiceWiseIdleDataWorker.set(queue: "background_azure_idle_queue").perform_async(options) }
    else
      batch.jobs { Azure::Idle::ServiceWiseIdleDataWorker.perform_async(options) }
    end
  end

end
