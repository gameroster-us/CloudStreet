class Adapters::CredentialVerifier < CloudStreetService

  def self.call(params, &block)
    if params[:adapter_id].present?
      adapter = Adapter.find(params[:adapter_id])
    else
      klass = ActionController::Base.helpers.sanitize(params[:type])
      klass = klass.safe_constantize rescue ''
      directory_adapter = klass.directoried.first if klass.present?
      adapter = directory_adapter.dup
    end
    adapter.assign_attributes(params.except(:type, :adapter_id, :gcp_access_keys).reject { |_, v| v.blank? })
    if adapter.type == "Adapters::Azure"
      adapter.azure_account_type = params[:azure_account_type]
      old_client_id = adapter.client_id
      reset_exports = params[:adapter_id].present? && adapter.azure_account_type.eql?('ss') && old_client_id != adapter.client_id
    elsif adapter.is_gcp?
      adapter.gcp_access_keys = JSON.parse(params[:gcp_access_keys]) rescue {}
    end
    response  = adapter.validate_credentials? 
    if response
      status Status, :success, {message: 'Credentials are Valid', data: response, reset_exports: reset_exports}, &block
    else
      status Status, :error, {message: 'Credentials are invalid'}, &block
      return false
    end
  rescue ::Adapters::InvalidAdapterError => e
    status Status, :error, {message: e.message}, &block
  end

end
