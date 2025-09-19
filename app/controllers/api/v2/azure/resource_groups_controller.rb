class Api::V2::Azure::ResourceGroupsController < Api::V2::SwaggerBaseController

  def index
    Azure::ResourceGroup::Fetcher.fetch(fetcher_params, current_tenant) do |result|
      result.on_success { |response| respond_with_user_and response[:resource_groups], represent_with: Azure::ResourceGroupsRepresenter, total_records: response[:total_records], status: 200 }
      result.on_error   { |errors| render status: 500, json: { errors: errors } }
    end
  end

  private

  def fetcher_params
    params.permit(:adapter_id, :name, :page, :per_page, :adapter_group_id)
  end

end
