class ServiceGroupSetting < ApplicationRecord
  belongs_to :adapter

  def self.create_and_update_group_setting_configuration(adapter, service_tag_key)
    service_group_setting = ServiceGroupSetting.find_or_create_by(adapter_id: adapter.id)
    existing_key = service_group_setting.whitelisted_tag_keys.first
    tag_key = service_tag_key.present? ? [service_tag_key.strip] : []

    # Update only when tag-key is changed
    service_group_setting.update_attribute(:whitelisted_tag_keys, tag_key) if tag_key.first != existing_key
    CloudStreet.log "========== Updated service_group_setting of adapter - #{adapter.id} ======="
    CloudStreet.log "========== Existing tag_key - #{existing_key} / New tag_key = #{tag_key.first}======="
    ServiceGroups::UpdateMultipleGroupsWorker.perform_async(adapter.id, existing_key, tag_key.first)
  end

  def self.create_and_update_group_setting_configuration_aws(adapter, service_tag_keys)
    service_group_setting = ServiceGroupSetting.find_or_create_by(adapter_id: adapter.id)
    existing_keys = service_group_setting.whitelisted_tag_keys
    tag_keys = service_tag_keys.present? ? service_tag_keys.map(&:strip) : []

    # Update only when tag-key is changed
    # service_group_setting.update_attribute(:whitelisted_tag_keys, tag_key) if tag_key.first != existing_key
    service_group_setting.update_attribute(:whitelisted_tag_keys, tag_keys) if tag_keys.to_set != existing_keys.to_set
    CloudStreet.log "========== Updated service_group_setting of adapter - #{adapter.id} ======="
    CloudStreet.log "========== Existing tag_key - #{existing_keys} / New tag_key = #{tag_keys}======="

    # We need to handle this before Finalizing the changes because for AWS we are not storing the single tag_key for
    # service-setting, instead we will be storing multiple tag-keys
    ServiceGroups::UpdateMultipleGroupsWorker.perform_async(adapter.id, existing_keys, tag_keys)
  end
end
