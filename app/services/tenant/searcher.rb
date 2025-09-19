require 'will_paginate/array'

class Tenant::Searcher < CloudStreetService
  def self.find(tenant_id, &block)
    tenant = Tenant.find_by(id: tenant_id)
    if tenant.present?
      status Status, :success, tenant, &block
    else
      status Status, :error, nil, &block
    end
  end

  def self.find_own_tenants(organisation, user, params = {}, &block)
    tenants = organisation && organisation.tenants.order(created_at: :desc)
    status Status, :success, tenants || [], &block
  end

  def self.find_available_tenants(organisation, user, &block)
    tenants = user.tenants.where(organisation_id: organisation.id).select(:id, :name, :is_default)
    status Status, :success, tenants, &block
  end

  def self.fetch_tenant_currency(current_tenant, &block)
    tenants = Tenant.select(:id, :enable_currency_conversion, :default_currency).where(id: current_tenant.id)
    status Status, :success, tenants || [], &block
  end

  def self.fetch_tenants_list(organisation, user, params = {}, &block)
    tenants = organisation && organisation.tenants

    # Seaching by Tenant name
    search_text = params["search_text"]
    tenants = tenants.where("lower(name) LIKE ?", "%#{search_text.downcase}%") if search_text.present?

    # Searched by assigned user are present in the tenant assigned user if any matched then tenant is displayed
    params_assigned_user_ids = params.key?(:assigned_user) ? params[:assigned_user].split(',') : []
    # tenants = tenants.select { |tenant| (tenant.tenant_users.includes(:user).pluck(:user_id) & params_assigned_user_ids).any? } if params_assigned_user_ids.any?
    tenants = tenants.joins(:tenant_users).where(tenant_users: {user_id: params_assigned_user_ids}) if params_assigned_user_ids.any?

    # Sorting by Tenant name
    sorting = params['sort']
    if sorting.present?
      tenants = tenants.order(name: sorting)
    else
      tenants = tenants.order(name: :ASC)
    end

    if params[:page_number].present? && params[:page_size].present?
      tenants = tenants.paginate(page: params[:page_number].to_i, per_page: params[:page_size].to_i)
      total_records = tenants.total_entries
    end

    tenants.includes(tenant_users: [:user]) if tenants.any?

    response = { tenants: tenants, total_records: total_records || 0 }
    status Status, :success, response, &block
  end

  def self.fetch_assigned_users(organisation, user, params = {}, &block)
    search_term              = params[:keyword_filter_by_name].presence
    per_page                 = (params[:per_page].presence || 50).to_i
    page                     = (params[:page].presence || 1).to_i

    tenants = organisation.tenants.includes(:adapters, tenant_users: [:user])
    result = []

    tenants.each do |tenant|
      tenant.tenant_users.includes(:user).each do |tenant_user|
        user = tenant_user.user
        temp = {
          id: user.id,
          name: (user.invited? ? user.unconfirmed_email : user.username)
        }

        result << temp if (search_term.present? && temp[:name].include?(search_term)) || search_term.nil?
      end
    end

    result = result.uniq { |res| res[:id] }
    total_records = result.count
    result = result.paginate(page: page, per_page: per_page)

    status Status, :success, [result, total_records], &block
  rescue StandardError => e
    status Status, :error, e.message, &block
  end

  def self.tenant_users(tenant, _filters = {}, &block)
    tenant_users = tenant.users.active.select(:id, :name, :username, :email, :user_type).distinct
    status(Status, :success, tenant_users, &block)
  rescue StandardError => e
    status(Status, :error, e, &block)
  end
end
