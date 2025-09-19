# frozen_string_literal: true

# Terminator Class for Azure
class TaskService::Actions::Azure::Terminator < CloudStreetService
  ALLOWED_RESOURCE_TYPE = ['Azure::Resource::Compute::VirtualMachine',
                           'Azure::Resource::Compute::Disk',
                           'Azure::Resource::Compute::Snapshot',
                           'Azure::Resource::Database::MySQL::Server',
                           'Azure::Resource::Database::SQL::Server',
                           'Azure::Resource::Database::MariaDB::Server',
                           'Azure::Resource::Database::PostgreSQL::Server',
                           'Azure::Resource::Database::SQL::DB',
                           'Azure::Resource::Network::LoadBalancer',
                           'Azure::Resource::Network::PublicIPAddress'].freeze

  def self.call(resource, **params, &block)
    return status ServiceStatus, :not_supported, resource, &block unless ALLOWED_RESOURCE_TYPE.include?(resource.type)

    unless resource.adapter.active?
      status ServiceStatus, :inactive_adapter, resource, &block
      return resource
    end

    response_status, response = terminate(resource)
    return status ServiceStatus, :success, resource, &block if response_status.eql?(:success)

    raise StandardError, 'resource not found' if response.try(:[], :error_code).eql?('ResourceNotFound')

    ESLog.info "=========#{resource.name}========response status: #{response_status}====response: #{response.inspect}"

    raise StandardError, response.try(:[], :error_message)
  rescue StandardError => e
    ESLog.error "=====error==========Resource Terminator: #{e.message}========================="
    status ServiceStatus, :failed, e, &block
    resource
  end

  def self.terminate(resource)
    ESLog.info "---------------Terminating Resource #{resource.name}-------------"
    response_status, response = resource.delete_resource
    if response_status.eql?(:success)
      ESLog.info "Delete_resource run successfully for #{resource.name} "
    else
      ESLog.info "Delete_resource failed for #{resource.name}"
    end
    resource.reload
    [response_status, response]
  end
end
