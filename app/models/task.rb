class Task < ApplicationRecord

  include Authority::Abilities
  include IceCube
  include Filterable
  include TaskService::ModelHelpers::Scheduler
  include TaskService::ModelHelpers::Updater
  include TaskService::ModelHelpers::Delete
  include TaskService::ModelHelpers::Executor
  include TaskService::ModelHelpers::Fetcher

  self.authorizer_name = "TaskAuthorizer"

  serialize :schedule
  enum task_type: { sync: 0, env_start: 1, env_stop: 2, env_terminate: 3, backup_services: 4, env_start_stop: 5, env_ec2_right_size: 6, recommendation_policy_action: 7 }

  store_accessor :data, :tag_operator, :auto_sync_to_cs_from_aws, :backup_policy_ids, :environment_tags, :event_for, :additional_conditions_value, :additional_conditions, :is_perform_backup, :script_id, :notify_to_tag_name, :email_notification, :is_dry_run, :is_allow_opt_out, :is_append_email_domain, :notify_to_email, :is_exclude_spot_instances, :provider, :notify, :start_stop_next_execuation_time, :start_stop_last_execuation_time, :opt_out_last_updated, :recommendation_policy_id

  store_accessor :notification_schedule, :hours_before_notification
  store_accessor :end_schedule, :ends, :end_datetime, :end_after_occurences

  attr_accessor :email_roles, :email_users, :script_name, :task_accessibility

  ## Association
  belongs_to :account
  belongs_to :creator, class_name: "User", foreign_key: "created_by"
  belongs_to :parent, class_name: 'Task'
  belongs_to :tenant
  has_and_belongs_to_many :environments
  has_many :adapters_tasks
  has_many :adapters, through: :adapters_tasks
  # has_and_belongs_to_many :services
  # has_and_belongs_to_many :snapshots
  has_many :task_details, dependent: :destroy, class_name: "TaskDetails"
  has_many :adapter_groups_tasks
  has_many :adapter_groups, through: :adapter_groups_tasks, dependent: :destroy, class_name: "ServiceGroup"

  ##Validations
  before_validation :generate_schedule
  validates :title, presence: true
  validates :adapter_ids, presence: true, if: ->(args) { sync? }
  validates :environment_ids, presence: true, if: ->(args) { (env_start? || env_stop? || env_terminate? || env_start_stop? || backup_services?) && environment_tags.blank? }
  validates :environment_tags, presence: true, if: ->(args) { (env_start? || env_stop? || env_terminate? || env_start_stop? || backup_services?) && environment_ids.blank? }
  validates :backup_policy_id, presence: true, if: ->(args) { backup_services? }
  validates :task_type, presence: true, inclusion: { in: %w[sync env_start env_stop env_terminate backup_services env_start_stop env_ec2_right_size recommendation_policy_action], message: "%<value>s is not a valid task_type" }
  validates :start_datetime, presence: true
  validates :hours_before_notification, presence: true, if: -> { notify? }
  validates :tenant_id, presence: true
  validate :active_title_should_be_unique
  validate :env_with_tags_exists, if: ->(args) { (env_start? || env_stop? || env_terminate? || env_start_stop? || backup_services?) && environment_tags.present? }
  validate :end_datetime_cannot_be_before_the_start_datetime, unless: -> { persisted? }
  validate :sync_only_normal_adapters, if: -> { sync? }

  #Scops
  scope :with_policy_names, -> { select("*,(SELECT array_to_string(array_agg(p.name), ', ') FROM backup_policies as p where (tasks.data->'backup_policy_ids')::jsonb ? p.id::text) as policy_names") }
  #TOCheck
  scope :by_account_and_environment_tags, ->(account_id, env_tags) { where("account_id = ? AND (data->'environment_tags')::jsonb <@ ?", account_id, env_tags.to_json) }
  scope :futuer_tasks_excluding_occurences_type, -> { where("(repeat IS FALSE AND start_datetime > :current_time) OR (repeat IS TRUE AND ((tasks.end_schedule->>'ends' = 'false') OR (end_schedule->>'ends' = 'true' AND (end_schedule->>'end_datetime')::timestamp > :current_time)))", current_time: Time.now) }
  scope :future_specific_occurences, -> { where("(end_schedule->'end_after_occurences')::text::int > 0") }
  # Backup policy tasks for environemnt
  scope :by_backup_policies, ->(policy_ids) { where(backup_policy_id: policy_ids) }
  scope :env_start_stop, -> { where(task_type: 'env_start_stop') }
  scope :region_wise_tasks, ->(region_ids) { where(region_ids.each_with_object([]) { |h, memo| memo << "'#{h}' = ANY (region_ids)" }.join(" OR ")) }

  scope :repeat_tasks, -> { where("next_execuation_time IS NOT NULL AND last_execuation_time IS NOT NULL") }
  scope :future_tasks, -> { where("next_execuation_time IS NOT ?  AND last_execuation_time IS ?", nil, nil) }

  def self.init_from(current_user, params, current_tenant)
    task = new(params)
    task.schedule_type = params["schedule"]["occurrence"] if params["schedule"].present?
    task.interval_time = params["schedule"]["interval_time"] if params["schedule"].present?
    task.time_zone = params["time_zone"] if params["time_zone"].present?
    task.region_ids = params["region_ids"] if params["region_ids"].present?
    task.is_dry_run = params['is_dry_run'] if params['is_dry_run'].present?
    task.tenant_id = current_user.current_tenant
    task.data_prepared = false
    task.all_azure_resource_group = params['all_azure_resource_group'] if params['all_azure_resource_group'].present?
    if task.sync?
      task.adapter_ids = params['data']['adapter_ids']
    elsif task.task_type =~ /env_(start|stop|terminate|start_stop)/
      task.adapter_ids = if params['environment_tags'].present?
                           params['adapter_ids']
                         else
                           task.adapter_ids = Environment.get_adapter_ids(params['environment_ids']).uniq
                         end
    elsif task.backup_services?
      task.adapter_ids = params["adapter_ids"]
    end
    task
  end

  def set_progress_data(state, count=1)
    ActiveRecord::Base.transaction do
      reload.with_lock do
        ESLog.info "====TASk RECORD LOCk============="
        get_value = progress[state.to_s]
        ESLog.info "====#{title}===#{state}===#{get_value}==================="
        progress_data = progress
        progress_data[state.to_s] = get_value + count
        update_columns(progress: progress_data)
        ESLog.info "==#{title}=====#{progress}======"
        ESLog.info "====TASk RECORD LOCk==RELEASE==========="
      end
    end
  end

  def provider
    return "AWS" if type.nil?

    type.split('::').last
  end

  def permitted_adapter_ids
    adapters_tasks.access(true).pluck(:adapter_id)
  end

  def permitted_adapter_group_ids
    adapter_groups_tasks.access(true).pluck(:adapter_group_id)
  end

  def adapters_without_permissions
    adapters.where(id: adapters_tasks.access(false).pluck(:adapter_id))
  end

  # Added method to check the task data is prepared or not
  def services_prepared
    loop do
      reload
      break if data_prepared

      sleep(1)
    end
  rescue StandardError => e
    ESLog.error "=====#{e.message}===#{e.class}==for=#{title}-----#{id}== #{DateTime.now}===#{e.backtrace}==============="
    raise StandardError, "In Rescue block"
  end

end