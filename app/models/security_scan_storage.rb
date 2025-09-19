class SecurityScanStorage
	include Mongoid::Document
  include Mongoid::Timestamps
  include Authority::Abilities
  self.authorizer_name = "SecurityScanStorageAuthorizer"

  SCANNABLE_SERVICES = %w(Services::Network::SecurityGroup::AWS Services::Database::Rds::AWS)

  field :account_id
  field :adapter_id
  field :region_id
  field :vpc_id
  field :service_id
  field :environments, type: Array
  field :service_type, type: String
  field :service_name, type: String
  field :state, type: String
  field :category, type: String
  field :provider_id, type: String
  field :scan_status, type: String
  field :scan_details, type: String
  field :scan_details_desc, type: String
  field :data, type: Hash
  field :tags, type: Array
  field :CS_rule_id, type: String
  field :rule_type, type: Array

  # indexes
  index({ account_id: 1 })
  index({ adapter_id: 1 })
  index({ service_type: 1 })
  index({ region_id: 1 })
  index({ scan_status: 1 })
  index({ rule_type: 1 })
  index({ account_id: 1, adapter_id: 1 })
  index({ adapter_id: 1, service_type: 1 })
  index({ adapter_id: 1, provider_id: 1 })
  index({ adapter_id: 1, region_id: 1 })
  index({ tags: 1 }, { collation: { locale: 'en', strength: 2 } })
  index({ adapter_id: 1, service_type: 1, tags: 1 })
  index({ adapter_id: 1, region_id: 1, service_type: 1 })
  index({ adapter_id: 1, scan_details: 1, region_id: 1 })
  index({ account_id: 1, adapter_id: 1, region_id: 1, category: 1, service_type: 1 })
  index({ adapter_id: 1, region_id: 1, scan_status: 1 })
  index({ adapter_id: 1, region_id: 1 })
  index({ adapter_id: 1, region_id: 1, scan_status: 1, rule_type: 1 })
  index({ account: 1, service_type: 1 })

  scope :by_environment, ->(environment_id){ elem_match(environments: {environment_id: environment_id}) }
  
  def self.to_csv(result)
    region_id_wise_map = Region.aws_region_id_map
    attributes = {service_name:  "Service Name", service_id: "Service Id",  state: "State", region_id: "Region", scan_status: "Scan Status", scan_details: "Details", scan_details_desc: "Description", tags: "Tags", CS_rule_id: "CloudStreet Rule Id", rule_type: "Type" }
    global_services = ["AWSAccount","AWSOrganisation","IamGroup","AWSIamRole","IamUser", "IamCertificate"]
    adapter_ids = result.pluck(:adapter_id)
    adapters_map = adapter_ids.present? ? Adapter.where(id: adapter_ids).pluck(:id,:name).to_h : []
    attributes = {service_name:  "Service Name", service_id: "Service Id",  state: "State", region_id: "Region", adapter_id: "Adapter", scan_status: "Scan Status", scan_details: "Rule Name", scan_details_desc: "Details", tags: "Tags", CS_rule_id: "CloudStreet Rule Id", rule_type: "Type" }
    csv = CSV.generate(headers: true) do |csv|
      csv << attributes.values
      result.each do |record|
        csv << attributes.keys.map do |attr|
          if(attr.to_s.eql?'environments')
            record.environments.pluck(:environment_name).present? ? record.environments.pluck(:environment_name).join(',') : 'N/A'
          elsif(attr.to_s.eql?'region_id')
            (global_services.include?record.service_type) ? "Global" : region_id_wise_map[record.region_id].try(:region_name)
          elsif(attr.to_s.eql?'adapter_id')
            adapters_map.blank? ? 'N/A' : adapters_map[record[:adapter_id]]
          elsif(attr.to_s.eql?'region_id')  
            region_id_wise_map[record.region_id].try(:region_name)
          elsif(attr.to_s.eql?'service_id')
            record.provider_id
          elsif(attr.to_s.eql?'service_name')
            record.service_name ||= record.provider_id
          elsif(attr.to_s.eql?'tags')
            record.tags.present? ? record.tags : nil
          elsif(attr.to_s.eql?'scan_status')
            record.scan_status.to_s.eql?('danger') ? 'critical' : record.send(attr)
          else
            record.send(attr)
          end
        end
      end
    end
    csv
  end

  def self.remove_scaned_data(adapter_ids, provider_ids)
    where(:adapter_id.in => Array[*adapter_ids], :provider_id.in => Array[*provider_ids]).delete_all
  end
  
end
