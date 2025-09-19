module AlertRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :id
  property :code
  property :additional_data
  property :message, getter: lambda { |args| get_message }
  property :created_at
  property :read
  property :read_at, getter: lambda { |args| self.read_at.strftime CommonConstants::DEFAULT_TIME_FORMATE if read_at}
  property :alert_type

  def get_message
    case code
    when "amis_archived_alert"
      I18n.t("messages.#{code}", archive_count: additional_data['archive_count'])
    when "adapter_deleted"
      I18n.t("messages.#{code}", name: additional_data['name'])
    when "service_scan_adapter_error"
      I18n.t("messages.#{code}", adapter_name: additional_data['adapter_name'])
    when "fetched_private_amis"
      I18n.t("messages.#{code}", adapter_count: additional_data['adapter_count'])
    when "fetched_encryption_keys"
      I18n.t("messages.#{code}")
    when "application_crossed_limit"
      I18n.t("messages.#{code}", application_name: additional_data['application_name'])
    when "template_created"
      I18n.t("messages.#{code}", additional_data.symbolize_keys)
    when "environment_created"
      I18n.t("messages.#{code}_from_#{additional_data['template_name'].present? ? 'template' : 'unallocated'}", additional_data.symbolize_keys)
    when "synced_s3_buckets"
      I18n.t("messages.#{code}")
    when "env_reload_completed"
      I18n.t("messages.#{code}")
    when "env_removed_from_management"
      I18n.t("messages.#{code}", name: additional_data['name'])
    when "synchronize_adapters_cloudtrail"
      I18n.t("messages.#{code}", adapters: additional_data['adapters'])
    when "report_generated"
      I18n.t("messages.#{code}", adapter: additional_data['adapter'], month: additional_data['month'])
    when "event_notification"
      I18n.t("messages.#{code}", title: additional_data['title'], time: additional_data['time'])
    when "report_error"
      I18n.t("messages.#{code}", adapter: additional_data['adapter'], month: additional_data['month'])
    when "limit_warning"
      I18n.t("messages.#{code}", adapter: additional_data['budget_name'])
    when "limit_crossed"
      I18n.t("messages.#{code}", adapter: additional_data['budget_name'])
    when 'saas_subscription_failed'
      I18n.t("messages.#{code}", message: additional_data['message'])
    else
      I18n.t("messages.#{code}")
    end
  end
end
