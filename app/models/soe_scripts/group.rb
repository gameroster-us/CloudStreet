class SoeScripts::Group < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = "SoeScripts::GroupsAuthorizer"

  attr_accessor :source, :attached_soe_scripts

  has_and_belongs_to_many :accounts
  belongs_to :sourceable, polymorphic: true
  has_many :soe_scripts, class_name: "SoeScript", foreign_key: 'soe_scripts_group_id'
  has_many :machine_image_configurations_soe_scripts, through: :soe_scripts
  has_many :machine_image_configurations, through: :machine_image_configurations_soe_scripts
  accepts_nested_attributes_for	:soe_scripts, allow_destroy: true
  validates :supported_os, presence: true
  validates :name, length: {minimum: 3, maximum: 255 }, presence: true
  validates :sourceable_id, presence: true
  validates :sourceable_type, presence: true, inclusion: { in: %w(Account SoeScripts::RemoteSource),
    message: "%{value} is not a valid source" }
  validates_uniqueness_of :name, scope: [:sourceable_id, :sourceable_type], message: "%{value} has already been taken"

  scope :name_like, -> (value) { where("soe_scripts.name ILIKE ? OR soe_scripts_groups.name ILIKE ?","%#{value}%", "%#{value}%") }
  scope :type, -> (value) { where(soe_scripts: {script_type: [value,SoeScript::ANY_TYPE]}) }
  scope :supported_os_like, -> (value) { where("soe_scripts_groups.supported_os ILIKE ?","%#{value}%") }
  scope :sourceable_id, -> (value) { where(sourceable_id: value) }

  class << self

    def get_counters(group_ids)
      hash = {}
      SoeScripts::Group.select("soe_scripts_groups.id, COUNT(DISTINCT machine_image_configurations.id) as counter").
        where(id: group_ids).joins(:machine_image_configurations_soe_scripts).joins(:machine_image_configurations).
        group("soe_scripts_groups.id").
        where("machine_image_configurations.is_template = ?", false).each do |group|
        hash[group.id] = group.counter
      end
      hash
    end

    def is_valid_remote_format?
      true
    end

    def sync_from_remote(account, source, response)
      begin
        ActiveRecord::Base.transaction do
          start_time = Time.now
          attributes = JSON.parse(response.body)
          raise "invalid format" unless attributes.keys.include?("soe_scripts_groups")
          source.version = attributes["version"]
          source.save!
          attributes["soe_scripts_groups"].each do |group_data|
            group = source.soe_scripts_groups.find_or_initialize_by(id: group_data["id"])
            group.attributes = group_data.slice!("soe_scripts_attributes")
            group.save!
            group_data["soe_scripts_attributes"].values.each do|soe_attrs|
              script = group.soe_scripts.find_or_initialize_by(id: soe_attrs["id"])
              script.attributes = soe_attrs
              script.last_updated = start_time
              script.save!
            end
            group.soe_scripts.where("updated_at < ?", start_time).delete_all
          end
          source.soe_scripts_groups.where("updated_at < ?", start_time).delete_all
        end
      rescue Exception => e
        CloudStreet.log("#{e.class} #{e.message} #{e.backtrace}")
        source.errored
        raise e
      end        
    end
  end
end
