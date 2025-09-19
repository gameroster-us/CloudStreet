# frozen_string_literal: true

module ServiceAdviser::VmWare::ServiceRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :id
  property :name, getter: ->(_args) { tag }
  property :provider_id
  property :created_date, getter: ->(_args) { created_at.to_date }
  property :rightsize_information, getter: ->(_args) { (data || {}).dig('right_size_report') }
  property :additional_information
  property :days_old
  property :tags
  property :service_type, getter: ->(_args) { resource_type }
  property :state
  property :vcenter_id, getter: ->(_args) { vw_vcenter_id }
  property :vcenter_name, getter: ->(_args) { vw_vcenter.data['name'] }
  property :adapter_id, getter: ->(_args) { vw_vcenter.adapter_id }
  property :adapter_name, getter: ->(_args) { vw_vcenter.adapter&.name }
  property :get_monthly_estimated_cost, as: :monthly_estimated_cost
  property :get_daily_estimated_cost, as: :daily_estimated_cost


  def additional_information
    if vm?
      {
        cluster_name: vm_cluster&.tag,
        ram: data['memoryMB'],
        cores: total_cpu,
        guest_full_name: data['guest']['guestFullName'],
        guest_id: data['guest']['guestId'],
        guest_family: data['guest']['guestFamily']
      }
    elsif data_store?
      {
        data_center_name: data_center_name,
        total_capacity: total_capacity,
        free_space: free_space
      }
    end
  end

  def tags
    vcenter = VwVcenter.find(self.vw_vcenter_id)
    adapter = vcenter.adapter
    return [] unless adapter&.account.present?
    CurrentAccount.client_db = adapter.account
    tags_data = self.data['tag_data']
    if tags_data.present?
      tags_data.collect {|a| {"key": a['tag_key'], "value": a['tag_value']}}
    else
      []
    end
  end

  def days_old
    (Time.now - self['created_at']).to_i / (24 * 60 * 60)
  end

  def state
    data['powerState']
  end

  def data_center_name
    "#{parent.tag} (#{parent.provider_id})" if data_store? && parent&.data_center?
  end

  def total_capacity
    data['capacityMB']
  end

  def free_space
    data['freeSpaceMB']
  end

  def get_monthly_estimated_cost
    cost_by_hour * 24 * 30 unless cost_by_hour.blank?
  end

  def get_daily_estimated_cost
    cost_by_hour * 24 unless cost_by_hour.blank?
  end

end
