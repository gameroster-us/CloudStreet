# Task Details for GCP
class TaskDetails::GCP < TaskDetails
  #VM, Disk
  SERVICE_MAP = {
    'GCP::Resource::Compute::Disk' => 'TaskDetails::GCP::Resource::Compute::Disk',
    'GCP::Resource::Compute::VirtualMachine' => 'TaskDetails::GCP::Resource::Compute::VirtualMachine'
  }.freeze

  store_accessor :data, :provider_id, :region_id, :tags

  def self.bulk_import(task, services)
    ESLog.info "======in task_detail_bulk_import======#{task.title}======="
    import_data_array = []
    services.each do |service|
      data = { provider_id: service.provider_id, region_id: service.region_id, tags: service.try(:tags) || [] }
      task_detail_type = SERVICE_MAP[service.type]
      ESLog.info "=====#{task_detail_type}==============#{service.name}==="
      import_data_array.push({ adapter_id: service.adapter_id, task_id: task.id, type: task_detail_type, data: data, resource_identifier: service.provider_id })
    end
    # task.task_details.destroy_all if task.task_details.present?
    TaskDetails.import import_data_array, batch_size: 10000
    ESLog.info '======Bulk Import done================='
  end
end
