class AthenaAccountGroupTableUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :athena_group_sync, retry: false, backtrace: true

  CREATE_GROUP = 'create'.freeze
  UPDATE_GROUP = 'update'.freeze
  DELETE_GROUP = 'delete'.freeze

  def perform(org_identifier, type, service_group_id, action, old_group_name, optional_params)
    CSLogger.info "Updating athena table for organisation : #{org_identifier} , type: #{type}"
    case action
    when CREATE_GROUP
      Athena::AccountGroupService.create_group_records(org_identifier, type, service_group_id, optional_params)
    when UPDATE_GROUP
      Athena::AccountGroupService.update_group_records(org_identifier, type, service_group_id, old_group_name, optional_params)
    when DELETE_GROUP
      Athena::AccountGroupService.delete_group_records(org_identifier, type, service_group_id)
    end
    CSLogger.info "Updation done on athena table for organisation : #{org_identifier} , type: #{type}"
  end
end