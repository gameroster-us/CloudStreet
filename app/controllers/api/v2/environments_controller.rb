class Api::V2::EnvironmentsController < Api::V2::SwaggerBaseController
  before_action :authenticate_request!
  authorize_actions_for Environment, except: [:index]

  def index
    authorize_action_with_condition(:index, Environment)

    @cost_options = !!params[:displaycost] ? %i[current_month_charges current_month_estimate] : []

    EnvironmentSearcher.search(current_account, current_tenant, user, page_params, search_params) do |result|
      result.on_success { |environments| respond_with_user_and environments[0], represent_with: EnvironmentsDisplayRepresenter, total_records: environments[1], cost_options: @cost_options }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  private

  def search_params
    params.permit(:name, :adapter_id, :region_id, :to_date, :from_date, :state, :with_snapshots, :provider, :page, :per_page)
  end
end
