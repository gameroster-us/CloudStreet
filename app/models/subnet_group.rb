class SubnetGroup < ApplicationRecord
  include Authority::Abilities
  include AttributeCopier

  belongs_to :account
  belongs_to :region
  belongs_to :adapter
  belongs_to :vpc

  resourcify
  store_accessor :data, :uniq_provider_id, :base_subnet_uuids
  attr_accessor :subnet_services_associated
  validates :name, presence: true, :uniqueness => {
    case_sensitive: false,
    scope: :vpc_id,
    message: "Name is already taken"
  },length: { maximum: 255 }, :if => :is_available?
  validates :description, presence: true
  validates :vpc, presence: true

  default_scope  { order(:created_at) }

  def self.find_or_create_reusable_service(attrs, &block)
    subnet_group = fetch_reusable_service(attrs)
    subnet_group = SubnetGroup.new(attrs) unless subnet_group
    block.call(subnet_group)
  end

  def self.fetch_reusable_service(attrs)
    uniq_provider_id = attrs.delete(:uniq_provider_id) if attrs.keys.include?(:uniq_provider_id)
    subnet_groups = SubnetGroup.where(attrs)
    subnet_groups = subnet_groups.where("data ->> 'uniq_provider_id' = ?", uniq_provider_id) if uniq_provider_id
    subnet_groups.first
  end

  def is_available?
    params = { name: name, account_id: account_id, vpc_id: vpc_id, adapter_id: adapter_id,  region_id: region_id }
    params.merge!(state: 'available') if self.account.naming_convention_enabled?
    self.class.where(params).present?
  end

  def self.if_exists_by(adapter_id, account_id, region_id, vpc_id, name)
    find_by(adapter_id: adapter_id, account_id: account_id, region_id: region_id, vpc_id: vpc_id, name: name)
  end

  def self.by_provider_id(adapter_id, account_id, region_id, vpc_id, provider_id)
    where(adapter_id: adapter_id, account_id: account_id, region_id: region_id, vpc_id: vpc_id, provider_id: provider_id).first
  end

  def self.by_uniq_id(adapter_id, account_id, region_id, vpc_id, uniq_id)
    where(adapter_id: adapter_id, account_id: account_id, region_id: region_id, vpc_id: vpc_id).where("data ->>'uniq_provider_id' = ?", uniq_id).first
  end
end