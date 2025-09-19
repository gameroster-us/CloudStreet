class SoeScripts::RemoteSourcesController < ApplicationController
  authority_actions synchronize: 'create'
  before_action :authenticate, except: [:download_sample]
  # GET /soe_scripts/remote_sources
  def index
    # authorize_action_for(SoeScripts::RemoteSource)
    SoeScripts::RemoteSourcesService.list_all(current_account, page_params, list_params) do |result|
      result.on_success { |result| respond_with_user_and result[0], total_records: result[1] }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  # GET /soe_scripts/remote_sources
  def synchronize
    authorize_action_for(SoeScripts::RemoteSource)
    SoeScripts::RemoteSourcesService.synchronize(current_account, user) do |result|
      result.on_success { |result| render body: nil, status: 200 }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  # POST /soe_scripts/remote_sources
  def create
    authorize_action_for(SoeScripts::RemoteSource)
    SoeScripts::RemoteSourcesService.create(current_account, source_params) do |result|
      result.on_success { |repo| respond_with_user_and repo, represent_with: SoeScripts::RemoteSourceRepresenter }
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  # PATCH/PUT /soe_scripts/remote_sources/1
  def update
    authorize_action_for(SoeScripts::RemoteSource)
    SoeScripts::RemoteSourcesService.update(current_account, source_params) do |result|
      result.on_success { |repo| respond_with_user_and repo }
      result.on_validation_error { |errors| render status: 422, json: cloudstreet_error(:validation_error, errors) }
      result.on_error   { render body: nil, status: 500 }
      result.not_found  { render status: 404, json: {:message => "Record not found"} }
    end
  end

  # DELETE /soe_scripts/remote_sources/1
  def destroy
    authorize_action_for(SoeScripts::RemoteSource)
    SoeScripts::RemoteSourcesService.destroy(current_account, params[:id]) do |result|
      result.on_success { |repo| render body: nil, status: 200  }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def download_sample
    File.open(Rails.root.join('public',"sample.json"), 'rb')  do |f|
      send_data f.read, filename: "sample.json", type: "application/json", :disposition => "attachment"
    end
  end

  private

  def list_params
    params.permit(:name_like, :url_like, :state)
  end

    # Only allow a trusted parameter "white list" through.
    def source_params
      params.require(:soe_scripts_remote_source).permit(:id,:url, :name).tap {|args|
        args[:account_id] = current_account.id
      }
    end
end
