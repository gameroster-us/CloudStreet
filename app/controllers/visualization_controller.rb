class VisualizationController < ApplicationController
  authorize_actions_for VisualizationAuthorizer, actions: {unallocated: 'visual'}

  def unallocated
    EnvironmentSearcher.search_unallocated_environments_info(current_account.id, current_tenant, page_params, search_params, params) do |result|
      result.on_success { |environments_info| respond_with environments_info[0], represent_with: ::UnallocatedEnvironmentsDisplayRepresenter, total_records: environments_info[1] }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  private

  def search_params
    params.permit(:name, :adapter_id, :region_id, :to_date, :from_date, :state, :with_snapshots, :provider, :page, :per_page)
  end
end
