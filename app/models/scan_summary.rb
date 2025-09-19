class ScanSummary
	include Mongoid::Document

  field :account_id
  field :adapter_id
  field :region_id
  field :vpc_id
  field :environment_id
  field :category, type: String
  field :services_count, type: Integer  
  field :created_at, type: DateTime, default: ->{ Time.now }
  field :updated_at, type: DateTime, default: ->{ Time.now }

  def self.find_or_create_summary(service)
    filter = { adapter_id: service.adapter_id,
               account_id: service.account_id,
               region_id: service.region_id               
             }
    category = (service.class.to_s == 'Storages::AWS') ? 'storage' : service.type.split('::')[1].downcase
    filter.merge!(category: category)
    if category == 'storage'
      filter.merge!(environment_id: 'NA') if service.environments.pluck(:id).uniq.blank?
      ScanSummary.create_or_update(filter)
      service.environments.pluck(:id).uniq.each do |environment_id|
        filter.merge!(environment_id: environment_id)
        ScanSummary.create_or_update(filter)
      end
    else
      filter.merge!(environment_id: service.environment.id) if service.environment
      filter.merge!(environment_id: 'NA') unless service.environment
      ScanSummary.create_or_update(filter)
    end
  end

  def self.create_or_update(filter)
    record = ScanSummary.find_or_initialize_by(filter)
    record.services_count = record.new_record? ? 1 : record.services_count + 1
    record.save!
  end

  def self.remove(filters, adapter)
    ScanSummary.where(account_id: filters['account_id'], adapter_id: adapter.id).destroy_all
  end
end