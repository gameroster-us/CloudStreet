class Api::V2::Azure::SecurityScanStoragesController < Api::V2::SwaggerBaseController

  SERVICE_TYPE = {
    'Account' => 'Account',
    'Availability Set' => 'Azure::Resource::Compute::AvailabilitySet',
    'Disk' => 'Azure::Resource::Compute::Disk',
    'Load Balancer' => 'Azure::Resource::Network::LoadBalancer',
    'Maria DB' => 'Azure::Resource::Database::MariaDB::Server',
    'MySQL' => 'Azure::Resource::Database::MySQL::Server',
    'Network Interface' => 'Azure::Resource::Network::NetworkInterface',
    'PostgreSQL' => 'Azure::Resource::Database::PostgreSQL::Server',
    'Public IP Address' => 'Azure::Resource::Network::PublicIPAddress',
    'Route Table' => 'Azure::Resource::Network::RouteTable',
    'Security Group' => 'Azure::Resource::Network::SecurityGroup',
    'Snapshot' => 'Azure::Resource::Compute::Snapshot',
    'SQL Databases' => 'Azure::Resource::Database::SQL::DB',
    'SQL Server' => 'Azure::Resource::Database::SQL::Server',
    'Storage Account' => 'Azure::Resource::StorageAccount',
    'Subnet' => 'Azure::Resource::Network::Subnet',
    'Virtual Machine' => 'Azure::Resource::Compute::VirtualMachine',
    'Virtual Network' => 'Azure::Resource::Network::Vnet'
  }.freeze

  authorize_actions_for SecurityScanStorage,
  actions: {
    get_scan_summary_by_service_types: 'read',
    get_scan_summary_by_rules: 'read',
    get_scan_result: 'read'
  }

  before_action :check_validation, :only => [:get_scan_result, :get_scan_summary_by_rules]

  def get_scan_summary_by_service_types
    AzureSecurityScanner.get_scan_summery(current_account, current_tenant) do |result|
      result.on_success { |response| render json: response }
      result.on_error { |e| render json: { error_message: e.message }, status: 500 }
    end
  end

  def get_scan_result
    AzureSecurityScanner.get_scan_result(current_account, current_tenant, rule_params) do |result|
      result.on_success do |security_scan_results|
        respond_with_user_and security_scan_results, represent_with: Azure::AzureSecurityScanResultsRepresenter, location: nil
      end
      result.on_error { |e| render json: { error_message: e.message }, status: 500 }
    end
  end

  def get_scan_summary_by_rules
    AzureSecurityScanner.threat_by_rules(current_account, current_tenant, rule_params) do |result|
      result.on_success { |response| render json: response }
      result.on_error { |e| render json: { error_message: e.message }, status: 500 }
    end
  end

  private

  def check_validation
    if params[:adapter_id].present? && !params[:adapter_id].eql?('all')
      params[:provider_type] = 'Adapters::Azure'
      adapter = V2::Swagger::ValidationService.adapter_valid?(params) if params[:adapter_id].present? && !params[:adapter_id].eql?('All')
      return render json: { message: "Couldn't find Adapter with id=#{params[:adapter_id]}" }, status: 404 unless adapter
    end

    if params[:adapter_group_id].present?
      service_group = V2::Swagger::ValidationService.get_adapter_group(current_account, params[:adapter_group_id], 'Azure')
      return render json: { message: "ServiceGroup doesn't exist" }, status: 404 unless service_group.present?
    end
  end

  def rule_params
    prepare_params
    params.permit(:service_type, :page, :per_page, scan_status: [], rule_type: [], type: [], adapter_id: [], adapter_group_id: [])
  end

  def prepare_params
    params[:scan_status] = params[:scan_status].present? ? [params[:scan_status]] : []
    params[:adapter_group_id] = params[:adapter_group_id].present? ? [params[:adapter_group_id]] : []
    params[:type] = params[:type].present? ? [params[:type]] : []
    params[:rule_type] = params[:type]
    params[:adapter_id] = params[:adapter_id].eql?('all') ? [] : [params[:adapter_id]]
    params[:service_type] = SERVICE_TYPE[params[:service_type]]
  end
end
