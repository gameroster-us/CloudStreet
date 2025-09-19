# frozen_string_literal: false

module Azure
  # Service class to fetch and store azure builtin policy
  class AssesmentDataStoreService
    attr_reader :assesment_data_arr, :headers, :url, :adapter_id, :subscription_id

    def initialize(url, headers, adapter_id, subscription_id)
      @url = url
      @headers = headers
      @adapter_id = adapter_id
      @subscription_id = subscription_id
      @assesment_data_arr = []
    end

    def fetch_and_store
      fetch_scan_report
      destroy_old_record
      store_scan_storage
    end

    def fetch_scan_report
      while url
        begin
          response = RestClient::Request.execute(method: :get, url: url, headers: headers)
          response = response.code.eql?(200) ? JSON.parse(response) : {}
          @assesment_data_arr.concat(response['value'])
          @url = response['nextLink']
          CSLogger.info "****** Requesting for next link - #{url}"
        rescue Exception => e
          CSLogger.error e.message
          @url = nil
        end
      end
    end

    private

    def destroy_old_record
      scan_storages = Azure::ScanStorage.where(adapter_id: adapter_id, subscription_id: subscription_id)
      scan_storages.destroy_all if scan_storages.present?
    end

    def store_scan_storage
      assesment_data = assesment_data_arr.map do |policy|
        {
          meta_data_id: policy['id'],
          policy_id: policy.dig('properties', 'policyDefinitionId')&.downcase,
          adapter_id: adapter_id,
          subscription_id: subscription_id,
          policy_names: policy.dig('properties','displayName'),
          policy_description: policy.dig('properties', 'description'),
          remediation_description: policy.dig('properties', 'remediationDescription'),
          categories: policy.dig('properties', 'categories'),
          preview: policy.dig('properties', 'preview'),
          severity: policy.dig('properties','severity'),
          user_impact: policy.dig('properties','user_impact'),
          implementation_effort: policy.dig('properties','implementation_effort'),
          threats: policy.dig('properties','threats')
        }
      end
      Azure::ScanStorage.collection.insert_many(assesment_data) unless assesment_data.blank?
      CSLogger.info "Compliance meta data store successfully for Adapter #{adapter_id}"
    end
  end
end
