class RegionsController < ApplicationController
  def index
    RegionSearcher.search(current_account, params[:adapter_id], params) do |result|
      result.on_success { |regions| respond_with_user_and regions }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def list_all
    respond_with Region.aws, represent_with: RegionsRepresenter
  end

  def enable_disable_region
    return_val = RegionManager.enable_disable(current_account, params[:enabled], params[:disabled]) 
    render json: { success: return_val } 
  end  

end
