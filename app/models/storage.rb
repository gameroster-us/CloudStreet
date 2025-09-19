class Storage < ApplicationRecord
  belongs_to :account
  belongs_to :region
  belongs_to :adapter

  alias_attribute :name, :key

  has_many :environment_storages, dependent: :destroy
  has_many :environments, through: :environment_storages
  accepts_nested_attributes_for :environment_storages
  default_scope { order('key asc') }

  def self.format_attributes_by_raw_data(aws_service)
    {
      key: aws_service,
      creation_date: aws_service.creation_date,
      owner_id: aws_service.owner_id,
      owner_display_name: aws_service.owner_display_name,
      access_control_list: aws_service.access_control_list,
    }
  end

  def update_bucker_acl(storage_connection, threat_scan = true)
    begin
      dir = storage_connection.directories.get(self.key)
      return if dir.blank?
      res = storage_connection.get_bucket_acl(self.key)
      acl = res.body
      result_set = fetch_bucket_properties(storage_connection)
      self.data = result_set
      self.data_will_change!
      self.owner_id = acl["Owner"]["ID"]
      self.owner_display_name = acl["Owner"]["DisplayName"]
      self.access_control_list = acl["AccessControlList"]
      self.save
      self.scan_and_update_threat_if_any if threat_scan
    rescue => e
      CloudStreet.log e.message
      CloudStreet.log e.backtrace
    end
  end

  def fetch_bucket_properties(storage_connection)
    ProviderWrappers::AWS::Storage::S3.fetch_properties(self.key, storage_connection)
  end

  def scan_and_update_threat_if_any
    SecurityScanWorker.perform_async("Storages::AWS",self.adapter_id,self.region_id,[self.key])
  end

  def get_acl_for_bucket(acl)
    self.owner_id = acl["Owner"]["ID"]
    self.owner_display_name = acl["Owner"]["DisplayName"]
    self.access_control_list = acl["AccessControlList"]
    self.save
  rescue => e
    CloudStreet.log e.message
    CloudStreet.log e.backtrace
  end
end
