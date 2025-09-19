class UserActivity
  include Mongoid::Document

  field :account_id
  field :tenant_id
  field :user_id
  field :type
  field :controller
  field :browser
  field :ip_address
  field :data, type: Hash
  field :lock_version, type: Integer #Provides Optimistic Locking
  field :created_at, type: DateTime, default: ->{ Time.now }
  field :updated_at, type: DateTime, default: ->{ Time.now }
  field :progress, type: Hash
  field :log_data, type: Hash

  index({ account_id: 1 })
  index({ tenant_id: 1 })
  index({ ip_address: 1})
  index({ created_at: 1})
  index({ 'data.username': 1})
  index({ 'data.name': 1})
  index({ user_id: 1})
  index({controller: 1})
  index({ account_id: 1, tenant_id: 1 })
  
  # default_scope { order('created_at DESC') }
  def self.list_account_activities(account_id, tenant, organisation)
    query = self.name.constantize.where(account_id: account_id)
    if tenant.is_default
      all_tenant_ids = organisation.tenants.pluck(:id)
      query.where(:tenant_id.in => Array[*all_tenant_ids]).all
    else
      query.where(tenant_id: tenant.id).all
    end
  end

  def username
    data[:username]
  end
  
  def name
    data[:name]
  end

  def action
    data[:action]
  end

  def status
    data[:status]
  end

  def child_organisation_name
    data[:child_organisation_name]
  end

  def organisation_purpose
    data[:organisation_purpose]
  end

  def child_org_access
    data[:child_org_access]
  end

  def set_response(activity_status, additional_data = nil)
    self.data[:status] = activity_status
  end

  class << self
    def init_activity(options)
      @activity = UserActivity.create
      @activity.user_id = options[:user].id
      @activity.account_id = options[:account_id] || options[:user].account_id
      @activity.tenant_id = options[:current_tenant_id] || options[:user].try(:current_tenant)
      @activity.controller = options[:controller]
      @activity.browser = options[:browser] if options[:browser]
      @activity.ip_address = options[:ip_address]  if options[:ip_address]
      @activity.type = options[:type] if options[:type]
      @activity.data = { 
        action: options[:action_name],
        status: options[:status]
      }
      @activity.data.merge!(username: options[:user].username)
      @activity.data.merge!(name: options[:name])        if options[:name]
      # @activity.data.merge!(params: options[:params])    if options[:params]
      @activity.data.merge!(environment_name: options[:environment_name])  if options[:environment_name]
      @activity.data.merge!(user_roles: options[:user_roles_name])  if options[:user_roles_name]
      @activity.data.merge!(template_name: options[:template_name])  if options[:template_name]
      @activity.data.merge!(manage_username: options[:manage_username]) if options[:manage_username]
      @activity.data.merge!(group_name: options[:group_name]) if options[:group_name]
      @activity.data.merge!(script_name: options[:script_name])  if options[:script_name]
      @activity.data.merge!(dry_run: options[:dry_run])  if options[:dry_run]
      @activity.data.merge!(enable_disable_status: options[:enable_disable_status])  if options[:enable_disable_status]
      @activity.data.merge!(enable: options[:enable])if options[:enable]
      @activity.data.merge!(is_delete_script: options[:is_delete_script]) if options[:is_delete_script]
      @activity.data.merge!(already_authenticate: options[:already_authenticate]) if options[:already_authenticate]
      @activity.data.merge!(child_organisation_name: options[:child_organisation_name]) if options[:child_organisation_name]
      @activity.data.merge!(saml_settings_user: options[:saml_settings_user]) if options[:saml_settings_user]
      @activity.data.merge!(organisation_purpose: options[:organisation_purpose]) if options[:organisation_purpose]
      @activity.data.merge!(child_org_access: options[:child_org_access]) if options[:child_org_access]
      @activity.log_data = options[:log_data] if options[:log_data]
      @activity.data.merge!(resource_name: options[:resource_name]) if options[:resource_name]
      @activity.data.merge!(service_type: options[:service_type]) if options[:service_type]
      @activity.data.merge!(provider: options[:provider]) if options[:provider]
      @activity
    end

    def by_username(username)
      # where("data.username" => /#{username}/i)
      where("data.username" => username)
    end

    def from_date(date)
      where(:created_at.gte => date)
    end

    def till_date(date)
      till_date = date
      where(:created_at.lte => till_date.to_date.end_of_day)
    end

    def by_controller(controller)
      controller.slice!("-integration") if ["slack-integration", "teams-controller"].include? controller  # Integration module maps to slack controller
      controller.slice!('aws_') if ['aws_budgets'].include? controller
      where(controller: controller )
    end

    def by_ip_address(ip_address)
      where(ip_address: /#{ip_address}/i)
    end

    def by_name(name)
      # where("data.name" => /#{name}/i)
      where("data.name" => name)
    end

    def by_search_name(name)
      where('data.name' => /#{name}/i)
    end

    def by_percentage(min,max)
      match_data = { "$and" => [{"progress.percentage" => { '$gte' => min.to_i, '$lte' => max.to_i }} ] }
      where(match_data)
    end

    def update_activity(task_id,activity_id)
      task = Task.find(task_id)
      activity = UserActivity.find(activity_id)
      progress_data = task.progress
      total = progress_data["total"]
      success = progress_data["success"]
      failure = progress_data["failure"]
      success_calculation = total == 0 ? 0 :((success.to_f/total.to_f)*100).round(2)
      failed_calculation = total == 0 ? 0 :((failure.to_f/total.to_f)*100).round(2)
      progress_data.merge!({"success_percentage" => success_calculation, "failed_percentage" => failed_calculation})
      activity.update(:progress => progress_data)
      ESLog.info "=====update_activity=====#{progress_data}======"
      if (task.backup_services? && (total == success + failure))
        ESLog.info "=========================sending mail for task #{task.title}========================="
        TaskService::Loggers::EmailLoggers.send_task_logs_email(task)
      end
    end

  end

  def self.import_from_dynamo
    # point to DynamoDB Local, comment out this line to use real DynamoDB
    Aws.config[:dynamodb] = { endpoint: "http://localhost:8000" } if Rails.env.development?

    dynamodb = Aws::DynamoDB::Client.new
    items = dynamodb.scan(:table_name => "cloudstreet_development_useractivities").items
    items.each do |item|
      m = UserActivity.new
      parsed_data = item['data'] rescue '{}'
      parsed_data = YAML.load(parsed_data) rescue {}
      m.data = parsed_data
      m.ip_address = item['ip_address']
      m.lock_version = item['lock_version'].to_i
      m.browser = item['browser']
      m.account_id = item['account_id']
      m.user_id = item['user_id']
      m.updated_at = item['updated_at'].to_i
      m.created_at = item['created_at'].to_i
      m.controller = item['controller']
      m.type = item['type']
      m.save
    end
  end
end
