class CostDataController < ApplicationController
	authority_actions get_daily_data: 'manage', get_monthly_data: 'manage'
	# authorize_actions_for User

	include Roar::Rails::ControllerAdditions

	respond_to :json

	def index
		
	end

	def top_five_environments
	    account = current_organisation.account
	    CostData.get_top_five_environments(account, params) do |result|
	      result.on_success { |json| render json: json, status: 200 }
	      result.on_error   { render body: nil, status: 500 }
	    end
	end

	def get_daily_data
		account = current_organisation.account
		CostData.get_daily_data(account) do |result|
		  result.on_success { |json| render json: json, status: 200 }
		  result.on_error   { render body: nil, status: 500 }
		end
	end

	def get_monthly_data
		account = current_organisation.account
		CostData.get_monthly_data(account) do |result|
		  result.on_success { |json| render json: json, status: 200 }
		  result.on_error   { render body: nil, status: 500 }
		end
	end

	def get_cost_by_adapter
	    account = current_organisation.account
	    CostData.get_cost_by_adapter(account, params) do |result|
	      result.on_success { |json| render json: json, status: 200 }
	      result.on_error   { render body: nil, status: 500 }
	    end
	end

	def get_cost_by_service
		account = current_organisation.account
	    CostData.get_cost_by_service(account) do |result|
	      result.on_success { |json| render json: json, status: 200 }
	      result.on_error   { render body: nil, status: 500 }
	    end
	end

	def get_charts_data
		account = current_organisation.account
	    CostData.get_charts_data(account) do |result|
	      result.on_success { |data| respond_with data , represent_with: CostDatumRepresenter, account: account }
	      result.on_error   { render body: nil, status: 500 }
	    end
	end

	def get_dashboard_charts_data
	    respond_to do |format|
		   format.any { render json: DashboardData.get_charts_data(current_organisation.account), status: :ok }
		end
	end

	def env_and_tmp_state_count
		#account = user.account
		env_state_count = Environment.where(default_adapter_id: current_tenant.adapter_ids)
		env_state_count = env_state_count.role_ids(user.user_role_ids) unless user.has_restricted_environment_view?
		env_state_count = env_state_count.group("state").count
		if env_state_count['running'].present? && env_state_count['stopping'].present?
      env_state_count['running'] += env_state_count['stopping']
    elsif env_state_count['stopping'].present?
      env_state_count['running'] = env_state_count['stopping']
    end
    if env_state_count['stopped'].present? && env_state_count['terminating'].present?
      env_state_count['stopped'] += env_state_count['terminating']
    elsif env_state_count['terminating'].present?
      env_state_count['stopped'] = env_state_count['terminating']
    end
		tmp_state_count = Template.where(adapter_id: current_tenant.adapter_ids).search_user_accessible_templates(user, current_tenant).group("state").count
		respond_to do |format|
		   format.any { render json: {:env_state_count=> env_state_count, :tmp_state_count=> tmp_state_count}, status: :ok }
		end
	end

end
