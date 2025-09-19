class EncryptionKey < ApplicationRecord
  belongs_to :account
  belongs_to :adapter
  belongs_to :region
  has_many :service_encryption_keys

  validates :account, :presence => true
  validates :adapter, :presence => true
  validates :region, :presence => true
  
  scope :created_keys_for_adapter, -> (adapter_id, region_id) { where(adapter_id: adapter_id, region_id: region_id, state: 'created') }
  scope :available_keys_for_account, -> (account_id) { where(account_id: account_id).where.not(:state => ["archived", " removed_from_provider"]) }
  scope :fetch_by_key_id, -> (key_id, adapter_id, region_id) { where(key_id: key_id, adapter_id: adapter_id, region_id:  region_id) }
  scope :fetch_enabled_keys, -> { where(enabled: true) }
  scope :fetch_by_enabled_region, ->(regions) { where(region_id: regions) }
  scope :skip_deletion_states,  -> { where.not(state: ['archived', 'removed_from_provider']) }

  state_machine initial: :pending do
    event :error do
      transition [:pending, :created, :error] => :error
    end
    event :created do
      transition [:pending, :error] => :created
    end
    event :archived do
      transition [:created, :pending, :error] => :archived
    end
    event :removed_from_provider do
      transition [:created, :error, :archived] => :removed_from_provider
    end
  end

  def self.find_or_create_key(key_info)
	  encryption_key = EncryptionKey.find_or_create_by(key_id: key_info['key_id'], account_id: key_info['account_id'],
	  	adapter_id: key_info['adapter_id'], region_id: key_info['region_id'])
	  encryption_key.attributes = key_info
    encryption_key.state = "created" if encryption_key.state != 'created'
	  encryption_key.save
 	end
end
