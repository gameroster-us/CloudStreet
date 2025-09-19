class Tag < ApplicationRecord
  include Authority::Abilities 
  self.authorizer_name = "TagAuthorizer"
  store_accessor :data , :use_nc_as_tag
  default_scope {order('created_at desc')}
  belongs_to :account
  belongs_to :creator ,foreign_key: :created_by, class_name: 'User'
  belongs_to :updator ,foreign_key: :updated_by, class_name: 'User'
  has_one :environment

  scope :provider_tags, -> { where(applied_type: 'Provider') }
  scope :application_tags, -> { where(applied_type: 'CloudStreet') }

  validates :creator, presence: true
  validates :updator, presence: true
  validates :account, presence: true
  validates :tag_type, inclusion: { in: ['text', 'dropdown', 'date'], :message => 'Tag Type must be text OR  dropdown OR date' }
  validates_length_of :description, maximum: 250, :message => 'Description should be less than or equal to 250 characters'


  validate :maximum_tags_per_account, :on => [:create, :update]
  # validate :date_tag_value, :on => [:create, :update]
  validate :validate_aws_prefix, :on => [:create, :update]
  
  validates :tag_key, uniqueness: { scope: :account_id,  message: I18n.t('validator.error_msgs.services.tags.oragnisation_tag')}

  attr_reader :is_template

  def use_name_param_as_tag_value?
    return false if self.use_nc_as_tag.blank?
    return to_bool(self.use_nc_as_tag)
  end

  def is_template=(value)
    @is_template = value
  end
  
  def to_bool(string)
    return true if string =~ (/^(true|t|yes|y|1)$/i)
    return false if string.nil? || string =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError, "invalid value: #{string}"
  end


  def is_template
    @is_template
  end

  def maximum_tags_per_account
    # return unless params[:action] == 'update'
    CSLogger.info "creating tags for #{self.applied_type}"
    return true unless self.applied_type.eql?('Provider')
    account = Account.find account_id
    tags = account.tags.where(applied_type: 'Provider')
    CSLogger.info "tags total count: #{tags.count}"
    if tags.count >= 48
      errors.add(:error_message, I18n.t('validator.error_msgs.services.tags.out_of_limit'))
      return false
    end
  end

  def validate_aws_prefix
    unless self.tag_key.blank?
      split_value = self.tag_key.downcase.split("aws:")
      errors.add(:tag_key, I18n.t('validator.error_msgs.services.tags.aws_prefix')) if !split_value.blank? && split_value.first.blank?
    end
  end

  # def date_tag_value
  #   return true unless self.tag_type.eql?('date')
  #   return true if self.tag_value =~ /^\d{4}(?:0?[1-9]|1[0-2])(?:0?[1-9]|[1-2]\d|3[01])$/
  #   errors.add(:invalid_date, I18n.t('validator.error_msgs.invalid_date_format'))
  #   return false
  # end

  def get_dropdown_nc_by_value(value)
    return if self.tag_type != "dropdown" || value.blank?
    self.tag_value.detect{ |v| v.include?(value) }.split("|").first.strip rescue nil
  end

  def update_tag_key_of_ris(user)
    url = "#{Settings.report_host}/api/v1/tags/update_or_delete_tag_key"
    org = Account.find(self.account_id).organisation
    RestClientService.post(url, user, {subdomain: org.subdomain, id: id, tag_key: tag_key, action_type: 'update' })
  end

  def self.delete_tag_key_of_ris(user, tag_id, account_id)
    url = "#{Settings.report_host}/api/v1/tags/update_or_delete_tag_key"
    org = Account.find(account_id).organisation
    RestClientService.post(url, user, {subdomain: org.subdomain, id: tag_id, action_type: 'delete_tag' })
  end

  state_machine initial: :pending do
    event :error do
      transition [:pending, :created, :error] => :error
    end
    event :created do
      transition [:pending, :error] => :created
    end
    event :archived do
      transition [:created, :pending, :error] => :archived
    end
  end

end
