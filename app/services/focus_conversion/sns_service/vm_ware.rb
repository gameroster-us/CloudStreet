# frozen_string_literal: true

# Class to call lambda service with CSMP mappings
class FocusConversion::SnsService::VmWare

  class << self

    def publish_to_sns(record)
      adapter = Adapter.find_by(id: record.adapter_id)

      # Trigger Sync for Focus Conversion for Mira enabled accounts only
      return unless adapter.account.organisation.mira_enable
      return unless ENV['FOCUS_CONVERSION_TRIGGER_SNS_TOPIC_ARN'].present?

      default_adapter = Adapters::AWS.get_default_adapter
      payload = fetch_metadata(adapter, record)
      sns_client = default_adapter.sns_client(APP_REGION)

      # Publish to SNS
      sns_client.publish(ENV['FOCUS_CONVERSION_TRIGGER_SNS_TOPIC_ARN'], payload.to_json)
    rescue StandardError => e
      Honeybadger.notify(e, error_class: 'FocusConversion::SNSService::VmWare', error_message: e.message, parameters: { adapter_id: adapter.id, subdomain: adapter.account.organisation.subdomain }) if ENV['HONEYBADGER_API_KEY']
    end

    def fetch_metadata(adapter, record)
      { provider: "VmWare",
        source_bucket: ENV['S3_BUCKET_NAME'],
        organisation_uuid: adapter.account.organisation.id,
        organisation_identifier: adapter.organisation_identifier,
        vw_vcenter_id: record.vw_vcenter_id,
        key: record.zip.path,
        adapter_id: adapter.id,
        record_creation_time: record.created_at }
    end

  end
end

