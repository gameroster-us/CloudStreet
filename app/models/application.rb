class Application < ApplicationRecord
  include Authority::Abilities
	self.authorizer_name = "ApplicationsAuthorizer"
  default_scope {order('applications.created_at desc')}
  belongs_to :account
  belongs_to :creator ,class_name: 'User',foreign_key: 'created_by_user_id'
  belongs_to :updator ,class_name: 'User',foreign_key: 'updated_by_user_id'
  has_many :environments

  validates :name, length: { maximum: 255,too_long: "%{count} characters is the maximum allowed" },  presence: true, :uniqueness => {
    case_sensitive: false,
    scope: :account_id
  }
  validates :creator, presence: true
  validates :updator, presence: true
  validates :account, presence: true
  validates :max_amount, :numericality => { :greater_than_or_equal_to => 0 }
  # after_save :check_application_cost

  scope :by_access_roles, ->(access_role_ids){ where("access_roles = '{}' OR access_roles @> ARRAY[?]::uuid[]", access_role_ids) }
  scope :set_restriction, ->(access_role_ids){ select("NOT(access_roles @> ARRAY['#{access_role_ids.join('\',\'')}']::uuid[] OR access_roles = '{}') as restriction") }
  scope :by_account_with_enviornments_count, -> (account_id){ select("applications.*, (select count('environments.id') from environments where environments.state NOT IN ('terminated','terminating') AND applications.id = environments.application_id) AS environments_count").where("applications.account_id = ? ", account_id).group('applications.id') }

  def check_application_cost
    return unless notify
    if self.is_max_limit_crossed?
      self.notify_max_limit_crossed 
      # alert = Alert.initialize_info_alert(:application_crossed_limit, {'application_id' => self.id, 'application_name' => self.name})
      # account.alerts << alert
      additional_data = { 'application_id' => self.id, 'application_name' => self.name }
      account.create_info_alert(:application_crossed_limit, additional_data)
    end
  end

  def unlinked_environments
    Environment.where(application_id: nil,account_id: account_id)
  end

  def non_terminated_environments
    environments.where.not(state: ['terminated', 'terminating'])
  end

  def projected_current_months_cost
    CostSummary.projected_current_months_cost(environment_id: self.environments.pluck(:id).uniq)
  end

  def is_max_limit_crossed?
    self.reload
    return false if self.max_amount.nil? || self.destroyed?
    (self.estimate_for_current_month + self.current_month_cost) > self.max_amount
  end

  def notify_max_limit_crossed
    @users = nil
    self.notify_to.each do |role_id|
      user_role = UserRole.find role_id
      @users = @users.nil? ? user_role.users.where(:account => self.account_id) : (@users + user_role.users.where(:account => self.account_id))
    end
    @users = @users.is_a?(Array) ? @users.uniq : @users 
    @users.each do |user|
      if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
        Notification.get_notifier.send_application_limit_crossed_email(user, self.name) rescue nil
      else
        Notification.get_notifier.delay(:queue => 'api',:retry => false).send_application_limit_crossed_email(user, self.name)
      end
    end if @users
  end

  def estimate_for_current_month
    self.environments.where.not(state: ['terminated','terminating']).inject(0){|sum,environment| sum += environment.get_current_month_estimate; sum}
  end

  def current_month_cost
    self.environments.where.not(state: ['terminated','terminating']).inject(0){|sum,environment| sum += environment.get_current_month_charges; sum}
  end

  def environments_count
    applications_environments.count
  end

  def environments_names
    applications_environments.pluck(:name)
  end

  def applications_environments
    self.environments.where(account_id: account_id).where.not(state: ['terminated','terminating'])
  end

end
