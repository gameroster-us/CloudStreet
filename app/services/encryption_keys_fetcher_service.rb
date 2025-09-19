class EncryptionKeysFetcherService < CloudStreetService
  def self.sync_encryption_keys(account, &block)
    unless account.active_aws_adapters.normal_adapters.present?
      status EncryptionKeyStatus, :validation_error, adapters: I18n.t('settings.global.encryption_keys.adapter_not_found'), &block
      return false
    end
    fetch_encryption_keys(account)
    status EncryptionKeyStatus, :success, true, &block
    true
  end

  def self.fetch_encryption_keys(account, &block)
    adapters = account.active_aws_adapters.normal_adapters
    
    batch = Sidekiq::Batch.new
    batch.description = "Encryption Key Fetcher Batch for adapters"
    params = {account_id: account.id}
    batch.on(:complete, EncryptionKeyFetcherCallback, params)
    batch.on(:success, EncryptionKeyFetcherCallback, params)
    batch.jobs do
      adapters.each do |adapter|
        unless adapter.verify_connections?
          additional_properties = { 'adapter_id' => adapter.id, 'adapter_name' => adapter.name }
          adapter.account.create_error_alert(:service_scan_adapter_error, additional_properties)
          next
        end
        EncryptionKeysFetchWorker.perform_async(adapter.id)
      end
    end
  end
  
  def self.fetch_encryption_keys_for_adapter(adapter)

    regions = Region.enabled_by_account(true, adapter.account_id).where(adapter_id: adapter.generic_adapter.id)
    return false unless regions.present?
    regions.each do |region|
      begin
        connection_object = ProviderWrappers::AWS::KMS.kms_agent(adapter, region.code)
        raw_keys_list = ProviderWrappers::AWS::KMS.fetch_key_list(connection_object)
        raw_aliases = ProviderWrappers::AWS::KMS.fetch_aliases_list(connection_object)

        raw_keys = raw_keys_list.inject([]) do |raw_keys, raw_key|
          res = fetch_key_info(connection_object, raw_key['KeyId'])
          alias_name = fetch_alias(raw_aliases, raw_key['KeyId'])
          res.merge!('key_alias' => alias_name, 'adapter_id' => adapter.id, 'region_id' => region.id, 'account_id' => adapter.account_id)
          raw_keys << res
        end
        save_keys(raw_keys, adapter, region)
        KMSKeyFetcher.get_aws_kms_keys(adapter,region)
      rescue Fog::AWS::KMS::Error => e
        CSLogger.error e.message
        break
      rescue ::Adapters::InvalidAdapterError => e
        CSLogger.error e.message
        return false
      rescue ArgumentError => error
        CSLogger.error error.message
        return false
      rescue Exception => error
        CSLogger.error error.message
        CSLogger.error error.backtrace
        return false
      end
    end
    
  rescue => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end

  def self.fetch_alias(raw_aliases, key_id)
    raw_aliases.each do |raw_alias|
      return raw_alias['AliasName'].sub!('alias/', '') if raw_alias['TargetKeyId'] == key_id
    end
  end

  def self.fetch_key_info(connection_object, key_id)
    res = ProviderWrappers::AWS::KMS.fetch_key_info(connection_object, key_id).inject({}) do |res, key_info|
      res.merge(key_info[0].underscore => key_info[1])
    end
    res
  end

  def self.save_keys(raw_keys, adapter, region)
    active_key_ids = raw_keys.each_with_object([]) do |raw_key, key_ids|
      EncryptionKey.find_or_create_key(raw_key) unless raw_key["key_alias"].is_a?(Array)
      key_ids << raw_key['key_id']
    end
    remove_outdated_keys(active_key_ids, adapter.id, region.id)
  end

  def self.remove_outdated_keys(active_key_ids, adapter_id, region_id)
    encryption_keys = EncryptionKey.created_keys_for_adapter(adapter_id, region_id)
    encryption_keys.each do |encryption_key|
      encryption_key.removed_from_provider! unless active_key_ids.include?(encryption_key.key_id)
    end
  end
  
  
  
  class EncryptionKeyFetcherCallback
    
    def on_complete(status, options)
      if status.failures != 0
        pp "EncryptionKeyFetcherCallback batch has failures"
      else
        account = Account.find(options["account_id"])
        account.create_info_alert(:fetched_encryption_keys, additional_data = {})
      end
    end
    
    def on_success(status, options)
      
    end
  end
  
end
