# frozen_string_literal: true

class Budget < ApplicationRecord

  has_many :tenant_budgets, dependent: :destroy
  has_many :tenants, through: :tenant_budgets
  has_many :budget_accounts, dependent: :destroy
  has_many :budget_groups, dependent: :destroy
  has_one :budget_resource_group, dependent: :destroy
  accepts_nested_attributes_for :tenant_budgets, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :budget_accounts, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :budget_groups, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :budget_resource_group, reject_if: :all_blank, allow_destroy: true
  validates_uniqueness_of :name, scope: [:type, :organisation_id], presence: true, :case_sensitive => false
  validates :max_amount, presence: true, length: { maximum: 18 }
  validates :description, presence: true
  validate :start_and_expire_month

  def validate_start_month
    error_message = 'Start Month Should not be less than 6 months from Current Month'
    errors.add(:base, error_message) if self.start_month < Date.today.beginning_of_month - 6.month
  end

  def start_and_expire_month
    error_message = 'Expires on month must not be greater than 12 months from the start month.'
    errors.add(:base, error_message) if self[:expires_date].present? && self[:start_month].to_date + 11.months < self[:expires_date]&.to_date
  end

  def budget_accounts_data
    budget_accounts.each_with_object([]).each do |adapter, accounts|
      accounts << {provider_account_id: adapter.provider_account_id, provider_account_name: adapter.provider_account_name }
    end
  end

  def budget_groups_data
    budget_groups.each_with_object([]).each do |grp, groups|
      groups << {group_id: grp.group_id, group_name: grp.group_name }
    end
  end

end
