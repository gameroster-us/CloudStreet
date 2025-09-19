class Synchronization < ApplicationRecord
  RUNNING = "running"
  SUCCESS = "success"
  FAILED = "failed"
  AUTO_SYNC_QUEUES = %w[background_azure_sync background_gcp_sync background_aws_sync].freeze

  belongs_to :account
  belongs_to :executor, class_name: "User", foreign_key: "executor_id"
  has_many :histories, foreign_key: 'synchronization_id', class_name: "::ServiceSynchronizationHistory"
  scope :running, -> { where("state_info ->> 'state' ='running'") }

  store_accessor :state_info, :state, :completed_state, :error, :auto_sync_to_cs_from_aws
  store_accessor :sync_info, :adapters_data
  validates_presence_of :account_id

  scope :list_by_account, ->(account){
    select("
      *,
      (SELECT array_to_string(array_agg(r1.region_name), ', ')  FROM regions as r1 where r1.id = ANY (region_ids) ) as region_names, 
      (SELECT array_to_string(array_agg(ad1.name), ', ') FROM adapters as ad1 where ad1.id = ANY (adapter_ids) ) as adapter_names
    ").where(account: account)
  }

  def self.get_friendly_id
    select('friendly_id').order('created_at DESC').first.try(:friendly_id) || 0
  end

  def self.get_last_sync(adapter_id)
    where("adapter_ids @> ARRAY['#{adapter_id}']::uuid[]").order('created_at DESC').first
  end

  def self.get_last_sync_start_time(adapter_id)
    get_last_sync(adapter_id).try(:started_at)
  end

  def force_teminate!
    self.state = FAILED
    self.state_info_will_change!
    self.save!
  end

  def self.log_sync_start(account, options)
    time = Time.now
    provider = options.has_key?("provider") ? options["provider"] : "AWS"
    provider_id = Adapter.directoried.where(type: "Adapters::#{provider}").first.id
    synchronization = self.new
    synchronization.account = account
    synchronization.state =  RUNNING
    synchronization.friendly_id = account.get_next_sync_counter
    synchronization.started_at = time
    synchronization.completed_at = time
    synchronization.executor_id = options["user_id"]
    synchronization.adapter_ids = options["adapter_ids"]
    auto_sync_to_cs_from_aws = (options["auto_sync_to_cs_from_aws"].eql?("true")||options["auto_sync_to_cs_from_aws"].eql?(true) ? true : false)
    options["adapter_ids"].map{ |adapter_id| synchronization.mark_adapter_wise_sync_status(adapter_id, RUNNING) }
    synchronization.auto_sync_to_cs_from_aws = auto_sync_to_cs_from_aws
    #what about regions of azure?
    if options["region_ids"].present?
      synchronization.region_ids = options["region_ids"]
    else
      synchronization.region_ids = Region.enabled_by_account(true,account.id).where(adapter_id: provider_id).pluck :id
    end
    synchronization.service_sync_status = {}
    synchronization.save!
    synchronization
  end

  def log_sync_complete(status = SUCCESS, error =nil, adapter_sync_status={})
    self.reload if self.persisted?
    self.state = status.eql?(SUCCESS) ? SUCCESS : FAILED
    self.completed_state = status
    self.completed_at = Time.now
    self.error = error
    self.adapter_wise_sync_status = self.adapter_wise_sync_status.merge(adapter_sync_status)
    self.save!
  end

  def mark_adapter_wise_sync_status(adapter_id, sync_status)
    if adapter_id.present? && sync_status.present?
      self.adapter_wise_sync_status = {} if self.adapter_wise_sync_status.blank?
      self.adapter_wise_sync_status = self.adapter_wise_sync_status.merge({adapter_id => sync_status})
      self.adapter_wise_sync_status_will_change!
    end
  end

  #AWS Sync when completing at a time few of record sync status was not updated
  #Added new method with lock process for updationg success of failed status.
  def mark_adapter_wise_sync_status_for_aws(adapter_id, sync_status)
    if adapter_id.present? && sync_status.present?
      ActiveRecord::Base.transaction do
        with_lock do
          CSLogger.info "========== Synchronization RECORD LOCked for AWS adapter ============="
          reload
          CSLogger.info "========== Synchronization RECORD LOCk Before Updating #{self.adapter_wise_sync_status} ==========="
          self.adapter_wise_sync_status = {} if self.adapter_wise_sync_status.blank?
          self.adapter_wise_sync_status = self.adapter_wise_sync_status.merge({adapter_id => sync_status})
          self.save
          CSLogger.info "========== Synchronization RECORD LOCk After Updation #{self.adapter_wise_sync_status} ==========="
          CSLogger.info "========== Synchronization RECORD LOCk Release ============="
        end
      end
    end
  end

  # GCP Synchronization almost complete at a same time that's why few of them sync status save as Running.
  # so adding new adapter method for only updating success or failed status.
  def mark_adapter_wise_sync_status_gcp(adapter_id, sync_status)
    if adapter_id.present? && sync_status.present?
      ActiveRecord::Base.transaction do
        with_lock do
          CSLogger.info "========== Synchronization RECORD LOCked ============="
          reload  # Skipping for the new record which is not saved.
          CSLogger.info "========== Synchronization RECORD LOCk Updating Before #{self.adapter_wise_sync_status} ==========="
          self.adapter_wise_sync_status = {} if self.adapter_wise_sync_status.blank?
          self.adapter_wise_sync_status = self.adapter_wise_sync_status.merge({adapter_id => sync_status})
          self.save
          CSLogger.info "========== Synchronization RECORD LOCk Updating After #{self.adapter_wise_sync_status} ==========="
          CSLogger.info "========== Synchronization RECORD LOCk Release ============="
        end
      end
    end
  end

  def is_running?
    self.state.eql?(RUNNING) rescue false
  end

  def is_completed_successfully?
    self.completed_state.eql?(SUCCESS) rescue false
  end

  def is_failed?
    self.completed_state.eql?(FAILED)
  end

  def get_logged_service(provider_id)
    self.histories.where(provider_id: provider_id).first
  end

  def update_service_status(service_name, flag, adapter_id)
    self.reload
    service_hash = self.service_sync_status[adapter_id]
    service_hash.merge!({"#{service_name}": flag })
    self.service_sync_status["#{adapter_id}"] = service_hash
    self.save
  end

  # def recalculate_sync_info
  #   self.sync_info = Hash.new
  #   adapters = Adapter.where(id: self.adapter_ids)
  #   adapter_data = []
  #   adapters.each do |adapter|
  #     h = Hash.new
  #     h[:adapter_id]= adapter.id
  #     h[:regions] = get_total_saving_on_vpcs(adapter)
  #     adapter_data << h
  #   end
  #   self.sync_info[:adapters_data] = adapter_data
  # end

  # def get_total_saving_on_vpcs(adapter)
  #   data = []
  #   self.region_ids.uniq.each do |region_id|
  #     region_hash = {:region_id=>region_id}

  #     filters = {:region_id => region_id, :account_id => self.account_id, adapter_id: adapter.id}
  #     snapshots = Snapshot.get_dettached_snapshots(filters)
  #     services = Service.get_dettached_services(filters)
  #     detached_services = snapshots.merge(services)
  #     region_hash[:region_savings] = detached_services.values.flatten.inject(0){|sum,service| sum + service.cost_by_hour }
  #     region_hash[:detached_services_count] = Synchronizers::AWS::SynchronizerService.get_services_count_to_allocate(region_id, adapter)
  #     data << region_hash
  #   end

  #   return data
  # end
end
