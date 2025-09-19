class GCPAccountMultiRegionsController < ApplicationController

  include Roar::Rails::ControllerAdditions

  respond_to :json

  def index
    GCP::AccountMultiRegion.search(current_account) do |result|
      result.on_success { |multi_regions| respond_with_user_and multi_regions, represent_with: GCP::AccountMultiRegionsRepresenter }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def enable_disable
    return_val = GCP::AccountMultiRegion.enable_disable(current_account, params[:enabled], params[:disabled])
    render json: { success: return_val }
  end

end
