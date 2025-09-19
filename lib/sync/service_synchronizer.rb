class ServiceSynchronizer
  attr_accessor :account_id, :data
  # {account_id: "id", adapters_id: ["id"]}
  def initialize(account_id)
    #todo permit attributes, :data, :sync_type
    @account_id = account_id
  end

  def sync_running?(id)
    ::REDIS.with do |conn|
      conn.get("sync_running_#{id}")
    end
  end

  def start_sync!(id)
    ::REDIS.with do |conn|
      conn.set("sync_running_#{id}", true)
      conn.expire("sync_running_#{id}", 60*60*1)
    end
  end

  def sync_progress_complete(resources_ids)
    resource_data = resources_ids.collect{|id|
      {
        id: id,
        name: "",
        sync_state: Synchronization::SUCCESS,
        total_count: 100,
        pending: 0,
        completed_count: 100,
        phase: 3
      }
    }
    ::NodeManager.send_sync_progress(@account_id, resource_data)
  end

  def sync_progress_start(resources)
    resources_data = resources.collect do |resource|
      {
        id: resource.id,
        name: resource.name,
        sync_state: Synchronization::RUNNING,
        total_count: 100,
        pending: 100,
        completed_count: 0,
        phase: 1
      }
    end
    ::NodeManager.send_sync_progress(@account_id, resources_data)
  end

  def send_progress(batch, adapter, phase)
    return unless sync_running?(adapter.id)
    adapter_data = [{
                      id: adapter.id,
                      name: adapter.name,
                      sync_state: Synchronization::RUNNING,
                      total_count: batch.total,
                      pending: batch.pending,
                      completed_count: batch.total - batch.pending,
                      phase: phase
    }]
    ::NodeManager.send_sync_progress(@account_id, adapter_data)
  end

  def mark_sync_complete(id)
    temp = "sync_running_#{id}"
    ::REDIS.with do |conn|
      conn.del("sync_running_#{id}")
    end
  end

  def alert_sync_complete(synchronization_id, adapter_data)
    account = Account.where(id: @account_id).first
    account.create_info_alert(
      :service_scan_complete, {
        synchronization_id: synchronization_id,
        adapter_id: adapter_data[:adapter_id],
        adapter_name: adapter_data[:adapter_name],
        provider_type: adapter_data[:provider_type]
      }
    ) if account
  end

  def failed(account_id, adapter_id)
    ::NodeManager.send_sync_progress(
      account_id, [{
                     id: adapter_id,
                     sync_state: Synchronization::FAILED,
                     error_message: "failed"
      }]
    )
  end

  def alert_service_adviser_dashbard_complete(synchronization_id)
    account = Account.where(id: @account_id).first
    account.create_info_alert(
      :service_adviser_dashboard_complete, {
        synchronization_id: synchronization_id
      }
    ) if account
  end
end
