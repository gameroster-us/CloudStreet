# frozen_string_literal: true

# this checks if server is Right Sizing VM
class CSIntegration::Server::Services::Azure::RightSizedVm
  attr_accessor :adapter_id, :account,:params

  def initialize(adapter_id, account, params = {}, resources)
    @adapter_id = adapter_id
    @account = account
    @params = params
    @resources = resources
  end

  def fetch_services
    region_id = Region.find_by_code(params[:region_code]).try(:id) || []
    active_right_sizing_vms = Azure::Rightsizing.get_right_sized_vms({adapter_id: adapter_id, region_id: Array[*region_id]})
    running_vm_size_hash = find_services(params, account, active_right_sizing_vms)
    right_sized_vms = active_right_sizing_vms.where(:provider_id.in => running_vm_size_hash.keys)
                                             .order_by(costsavedpermonth: 'ASC'.to_sym)
    return [] if right_sized_vms.blank?
    
    right_sized_vms = right_sized_vms.select { |rightsize_vm| rightsize_vm.instancetype.eql? running_vm_size_hash[rightsize_vm.provider_id] }
    right_sized_vms
  end

  def find_services(params, account, right_sized_vms)
    provider_ids = right_sized_vms.pluck(:provider_id)
    query = @resources[:vm].active.running_vm
                           .exclude_aks_resource_group_services
                           .exclude_databricks_resource_group_services
                           .where("provider_data->>'id' IN(?)", provider_ids)
                           .not_ignored_from(['vm_right_sizings'])
    query.pluck("provider_data->>'id'", "data->>'vm_size'").to_h rescue []
  end
end
