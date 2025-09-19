# frozen_string_literal: true

class SaRecommendation < ApplicationRecord

  include Authority::Abilities
  self.authorizer_name = 'SaRecommendationAuthorizer'

  STATE = ["assigned", "in-progress", "completed", "rejected", "cancelled"].freeze

  AZURE_UNOPTIMIZED = {
    'vm_right_sizings' => 'Azure::Rightsizing',
    'sqldb_rightsizing' => 'Azure::Rightsizing',
    'hybrid_benefit_vm' => 'Azure::Rightsizing',
    'hybrid_benefit_sql_db' => 'Azure::Recommend',
    'hybrid_benefit_elastic_pool' => 'Azure::Recommend'
  }

  AWS_UNOPTIMIZED = {
    'rightsized_ec2' => 'EC2RightSizing',
    'custom_rightsized_ec2' => 'EC2RightSizingExtendResult',
    'unused_provisioned_iops_rds' => 'MatricMaxUsageStorage',
    'unused_provisioned_iops_volumes' => 'MatricMaxUsageStorage',
    'rightsized_rds' => 'AWSRightSizing::Rds',
    'rightsized_s3' => 'AWSRightSizing::S3',
    'instances_sizing' => 'Services::Compute::Server::AWS',
    'rds_instances_sizing' => 'Services::Database::Rds::AWS'
  }

  scope :azure_recommendations, ->{ where(type: "SaRecommendations::Azure") }
  scope :aws_recommendations, ->{ where(type: "SaRecommendations::AWS") }
  scope :gcp_recommendations, ->{ where(type: "SaRecommendations::GCP") }

  validates_inclusion_of :state, :in => SaRecommendation::STATE.without("assigned", "cancelled"), if: :update_by_assignee?, on: :update
  validates_inclusion_of :state, :in => SaRecommendation::STATE.without("in-progress", "completed", "rejected", "cancelled"), on: :create

  validates :assign_to, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :assigner_comment, presence: true, on: :create
  validates :assignee_comment, presence: true, if: :update_by_assignee?, on: :update
  # validates_uniqueness_of :provider_id, scope: [:tenant_id, :service_type], case_sensitive: false, message: 'Service already assigned as task', on: :create

  attr_accessor :mec

  belongs_to :account
  belongs_to :adapter
  belongs_to :tenant
  belongs_to :recommendation_task_policy
  belongs_to :recommendation_policy
  has_many :task_histories,dependent: :destroy

  # Delegates
  delegate :state, to: :recommendation_task_policy, prefix: :policy, allow_nil: true
  delegate :state, to: :recommendation_policy, prefix: :policy, allow_nil: true

  def update_by_assignee?
    (self.state != 'assigned' && self.state != 'cancelled')
  end

  def recommendation_service
    klass = if self.type.eql?('SaRecommendations::GCP')
      GCP::Resource.active.find_by(provider_id: self.provider_id, adapter_id: self.adapter_id)
    elsif  self.type.eql?('SaRecommendations::Azure')
      Azure::Resource.active.where("provider_data->>'id' =? and adapter_id =?", self.provider_id, self.adapter_id).first
    else
      klass = ServiceAdviser::AWS::UNUSED_UNOPTIMIZED_MAP[self.service_type]
      if self.service_type.eql?("rightsized_ec2")
        klass.constantize.active_services.find_by("provider_id = ? and adapter_id = ?", self.provider_id, self.adapter_id)
      elsif self.service_type.eql?("rightsized_rds")
        klass.constantize.active_services.find_by("provider_id = ? and adapter_id = ?", self.provider_id, self.adapter_id)
      elsif self.service_type.eql?("rightsized_s3")
        klass.constantize.find_by("key = ? and adapter_id = ?", self.provider_id, self.adapter_id)
      elsif ['rds_snapshot','volume_snapshot'].include?(self.service_type)
        klass.constantize.active_snapshots.find_by(provider_id: self.provider_id, adapter_id: self.adapter_id)
      elsif ['amis'].include?(self.service_type)
        klass.constantize.active.find_by(image_id: self.provider_id, image_owner_id: self.adapter.aws_account_id)
      else
        klass.constantize.active_services.find_by(provider_id: self.provider_id, adapter_id: self.adapter_id)
      end
    end
  rescue Exception => e
    CloudStreet.log "#{e.message} ---#{e.backtrace}"
    nil
  end

  def recommendation_mec
    if type.eql?('SaRecommendations::AWS')
      calculate_aws_service_mec
    elsif type.eql?('SaRecommendations::Azure')
      calculate_azure_service_mec
    else type.eql?('SaRecommendations::GCP')
      calculate_gcp_service_mec
    end
  end

  def calculate_aws_service_mec
    service = self.recommendation_service
    return 0 unless service.present?

    currency_rate = self.tenant.current_currency_rate("AWS")
    mec = if SaRecommendation::AWS_UNOPTIMIZED[self.service_type].present?
      if self.service_type.eql?("rightsized_ec2")
        config = self.account.service_adviser_configs.aws_rightsized_ec2_default_config
        rightsizing_service_type = config.show_default_recommendation ? 'rightsized_ec2' : 'custom_rightsized_ec2'
        SaRecommendation::AWS_UNOPTIMIZED[rightsizing_service_type].constantize.where(instanceid: service.provider_id, Account: service.adapter.aws_account_id).first&.costsavedpermonth
      elsif self.service_type.eql?("rightsized_rds")
        SaRecommendation::AWS_UNOPTIMIZED[self.service_type].constantize.find_by("data ->>'provider_id' = ? and aws_account_id = ?", service.provider_id, service.adapter.aws_account_id)&.cost_save_per_month
      elsif self.service_type.eql?("rightsized_s3")
        SaRecommendation::AWS_UNOPTIMIZED[self.service_type].constantize.find_by("data ->>'key' = ? and aws_account_id = ?", service&.key, service.adapter.aws_account_id)&.cost_save_per_month
      elsif self.service_type.eql?("unused_provisioned_iops_rds")
        res = SaRecommendation::AWS_UNOPTIMIZED[self.service_type].constantize.where(adapter_id: service.adapter_id, provider_id: service.provider_id).first
        ((res.actual_estimation_cost - res.recommanded_estimation_cost)*24*30) || 0
      elsif self.service_type.eql?("unused_provisioned_iops_volumes")
        res = SaRecommendation::AWS_UNOPTIMIZED[self.service_type].constantize.where(adapter_id: service.adapter_id, provider_id: service.provider_id).first
        ((res.actual_estimation_cost - res.recommanded_estimation_cost)*24*30) || 0
      elsif self.service_type.eql?("instances_sizing")
        (service.data["legacy_instance_sizing"]["hourly_saving"]*24*30)
      elsif self.service_type.eql?("rds_instances_sizing")
        (service.data["legacy_instance_sizing"]["hourly_saving"]*24*30)
      end
    else
      cost_by_hour = if service.class.name.eql?("MachineImage")
        service.root_device_type.eql?('ebs') ? service.cost_by_hour : 0
      elsif service.type.eql?("Services::Compute::Server::AWS") && service.state.eql?('stopped')
        service.data['attached_volumes_cost'] || 0
      else
        service.try(:cost_by_hour) || 0
      end
      cost_by_hour * 24 * 30
    end

    (mec * currency_rate).round(2) rescue 0
  rescue Exception => e
    CloudStreet.log "#{e.message} ---#{e.backtrace}"
    0
  end

  def calculate_azure_service_mec
    service = self.recommendation_service
    return 0 unless service.present?
    currency_rate = self.tenant.current_currency_rate("Azure")
    klass =  SaRecommendation::AZURE_UNOPTIMIZED[self.service_type]
    mec = if SaRecommendation::AZURE_UNOPTIMIZED[self.service_type].present?
      klass.constantize.where(provider_id: self.provider_id, account_id: self.account_id).first&.costsavedpermonth || 0
    else
      ((service.cost_by_hour * 24 * 30)).round(2)  rescue 0
    end
    (mec * currency_rate).round(2) rescue 0
  end

  def calculate_gcp_service_mec
    service = self.recommendation_service
    return 0 unless service.present?

    currency_rate = self.tenant.current_currency_rate("GCP")

    if service.type.eql?('GCP::Resource::Compute::VirtualMachine') && service.vm_status.eql?('stopped')
      ((service.attached_disk_price || 0) * 730 * currency_rate).round(2) rescue 0.0
    else
      ((service.cost_by_hour * 730) * currency_rate).round(2) rescue 0
    end
  end

end
