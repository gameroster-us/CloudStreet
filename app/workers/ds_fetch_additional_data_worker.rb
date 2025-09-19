require "./lib/node_manager.rb"
class DsFetchAdditionalDataWorker
  include Sidekiq::Worker
  attr_accessor :retry_count

  def retry_count
    @retry_count || 0
  end
  sidekiq_options queue: :sync, :retry => 25

  sidekiq_retry_in do |count|
    30
  end

  def perform(id, options)
      json = {}
      template_cost = nil
      ::REDIS.with do |conn|
        json = conn.get(id)
        template_cost = JSON.parse(conn.get("#{options['region_code']}_cost"))
      end
      adapter = Adapters::AWS.find(options['adapter_id'])
      return if json.blank? || !json.is_a?(String)
      attributes = JSON.parse(json) 
      #Fetching additional data with multiple 3rd party API calls
      aws_record_class = AWSRecord.get_service_type(attributes[id]["service_type"])
      ds_record = aws_record_class.new(attributes[id])
      
      begin
        retries ||= 0
        ds_attributes = ds_record.class::SERVICE_CLASS.constantize.fetch_additional_data_for_sync(ds_record.provider_id, adapter, options['region_code'], {})
      rescue Excon::Error::Socket, Excon::Error::Timeout, Excon::Error::ServiceUnavailable => e
        CSLogger.error "Excon Exeption:: => #{e.message}.Retrying " if retries.eql?(0)
        if (retries += 1) < 3
          sleep 5
          print "."
          retry
        else
          ds_attributes = {}
        end
      rescue Exception, ::Adapters::InvalidAdapterError => e
        if retry_count >= 24
          ds_attributes = ds_record.set_default_addtional_data
        else
          raise e
        end
      end
      ds_record.data.merge!(ds_attributes)
      ds_record.synchronization_id = options['synchronization_id']
      begin
        ds_record.update_hourly_cost(template_cost)
        ds_record.save!
        ds_record.synchronize(options['auto_sync_to_cs_from_aws'])

        # if !ds_record.detached? && ds_record.type == "AwsRecords::Network::LoadBalancer::AWS"
        #   ::REDIS.with do |conn|
        #     conn.lpush("aws_record_ids", ds_record.id)
        #   end
        # end
      rescue Encoding::UndefinedConversionError => e
        CSLogger.error("UndefinedConversionError Logged By CloudStreet #{ds_record.attributes.inspect}")
        ds_record.attributes = DataStoreManager::Utf8Converter.convert_to_utf_8(ds_record.attributes)
        retry
      end
      ::REDIS.with do |conn|
        conn.del(id)
        conn.lrem(attributes[id]["adapter_id"], -1, id)
      end
    status = Sidekiq::Batch::Status.new(options["batch_id"])
    adapter_data = {
      id: options["adapter_id"],
      name: options["adapter_name"],
      sync_state: Synchronization::RUNNING,
      total_count: status.total,
      pending: status.pending,
      failure_info: status.failure_info,
      completed_count: status.total - status.pending,
      data: status.data,
      phase: 3
    }
    ::NodeManager.send_sync_progress(options["account_id"], [adapter_data])
  rescue ActiveRecord::RecordInvalid => e
    CSLogger.error("Error: #{e.class} #{e.message} #{e.backtrace} #{e.record.inspect}")
    raise e
  rescue Exception, ::Adapters::InvalidAdapterError => e
    unless (
      e.message.eql?("RequestLimitExceeded => Request limit exceeded.") ||
      e.message.eql?("Throttling => Rate exceeded") ||
      e.message.eql?("connect_read timeout reached") ||
      e.message.eql?("connect_write timeout reached")
    )
    CSLogger.error("Error: #{e.class} #{e.message} #{e.backtrace}")
    end
    raise e
  end

  sidekiq_retries_exhausted do |msg|
    begin
      Synchronization.connection_pool.with_connection do |conn|
        ::REDIS.with do |conn|
          conn.del(msg['args'].first)
        end
        adapter = Adapter.find(msg['args'].last["adapter_id"])
        adapter.update(sync_running: false) if adapter && adapter.sync_running
        synchronization = Synchronization.find(msg['args'].last["synchronization_id"])
        if synchronization.present?
          synchronization.mark_adapter_wise_sync_status_for_aws(msg['args'].last["adapter_id"], Synchronization::FAILED)
          synchronization.force_teminate!
        end
        ::NodeManager.send_sync_progress(
          msg['args'].last["account_id"], [{
            id: msg['args'].last["adapter_id"],
            sync_state: Synchronization::FAILED,
            error_message: "failure 1"
          }
        ])
      end
    rescue Exception => e
      CSLogger.error("#{e.class} : #{e.message} : #{e.backtrace}")
    end
  end
end
