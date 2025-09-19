class UpdatingServerRamSizeWorker

  include Sidekiq::Worker
  sidekiq_options queue: :sync, retry: false, backtrace: true
  def perform
    begin
      Organisation.active.joins(:account).each do |organisation|
        next unless organisation.adapters.present? & organisation.adapters.aws_normal_active_adapters.present?
        adapters = organisation.adapters.aws_normal_active_adapters
        adapters.each do |adapter|
          adapter_aws_server = Services::Compute::Server::AWS.where(adapter_id: adapter.id).find_in_batches(batch_size: 100) do |services|
            services.each do |service|
              service.store_ram_size
              service.save!
              CloudStreet.log "updated ram size for service #{service.id}"
            rescue Exception => e
              CloudStreet.log "============#{e.inspect}========="
              CloudStreet.log "exception  occured for service id: #{service.id}"
            end
          end
        end
      end
    rescue Exception => e
      CloudStreet.log "============#{e.inspect}========="
    end
  end

end