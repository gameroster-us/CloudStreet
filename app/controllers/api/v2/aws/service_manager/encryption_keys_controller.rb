class Api::V2::AWS::ServiceManager::EncryptionKeysController < Api::V2::ServiceManagerBaseController
  authorize_actions_for ServiceManagerAuthorizer,
  actions:  {
    index: 'read',
    sync_encryption_keys: 'read'
  }
  before_action :valid_aws_adapter, :valid_aws_service_group, :except => [:sync_encryption_keys]

  def index
    EncryptionKeysSearcherService.search(current_account, current_tenant, page_params, search_params) do |result|
      result.on_success { |encryption_keys| respond_with_user_and encryption_keys[0], total_records: encryption_keys[1], represent_with: EncryptionKeysRepresenter }
      result.on_error   { |errors| render status: 500, json: { errors: errors } }
      result.on_validation_error { |error_msgs| render status: 400, json: { validation_error: error_msgs } }
    end
  end

  def sync_encryption_keys
    EncryptionKeysFetcherService.sync_encryption_keys(current_account) do |result|
      result.on_success { |sync_encryption_keys| render json: sync_encryption_keys, status: 200 }
      result.on_validation_error { |error_msgs| render status: 400, json: { validation_error: error_msgs } }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  private

  def search_params
    params.permit(:adapter_name, :region_name, :page_size, :page_number, :adapter_group_id, :tags, adapter_id: [])
  end

end
