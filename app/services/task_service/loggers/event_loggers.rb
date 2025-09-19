# frozen_string_literal: true

# User activity logging for event
class TaskService::Loggers::EventLoggers < CloudStreetService
  extend ResponseHandler
  class << self
    ## Code for set activity log data
    def set_activity_log(service, result, data)
      data.symbolize_keys!
      activity_options = {
        module_name: 'Event Scheduler',
        action_name: data[:action_name],
        action_status: 'Success',
        action_message: 'Event Run Successfully',
        resource_owner: data[:action_owner_details].provider,
        resource_error_message: data[:from].eql?('vm_ware') ? vm_ware_error_message(result) : resource_error_message(data, result),
        action_user: data[:action_user]
      }

      activity = UserActivityLog.init_activity(service, activity_options, data) if data[:user_activity_id].present?
      if result.present? && data[:from].eql?('vm_ware')
        state = vm_ware_log_and_state(result, data, activity)
      elsif result.present?
        send("#{data[:action_name]}_task".to_sym, result, activity, data[:from])
        state = result.error || result.status == :failed ? 'failure' : 'success'
      elsif data[:adapter_access_log]
        activity.set_response("event_#{data[:from]}_adapter_unauthorized_for_tenant") if activity.present?
        state = 'failure'
      elsif data.key?(:opt_out) && activity.present?
        data.key?(:opt_out_user_activity) ? activity.set_response("event_#{data[:from]}_opt_out") : activity.set_response("event_#{data[:from]}_#{data[:action_name]}_opt_out")
      elsif data[:action_owner_details].is_dry_run
        activity.set_response("event_#{data[:from]}_#{data[:action_name]}_dry_run_success") if activity.present?
        state = 'success'
      elsif data[:from].eql?('recommendation_service')
        state = recommendation_service_log(data, activity)
      end
      activity.save! if activity.present?
      state = state.present? ? state : 'success'
      data[:action_owner_details].set_progress_data(state)
      data[:action_owner_details].reload
      UserActivity.update_activity(data[:action_owner_details].id, data[:user_activity_id]) if data[:user_activity_id].present?
      TaskService::ServiceHelpers::CompleteExecution.complete_task_execution(data[:action_owner_details], data[:run_now]) if data[:from].eql?('vm_ware') && !data.key?(:opt_out_user_activity)
    end

    ## Code for set error message in user activity log
    def error_message(result)
      return 'You are not authorized to perform this operation' if result.resources.message.include?('UnauthorizedOperation')

      result.resources.message
    end

    def resource_error_message(data, result)
      if data[:adapter_access_log]
        'error'
      elsif result.present?
        result.error.nil? && result.status == :failed ? error_message(result) : result.error
      elsif data.key?(:error)
        'error'
      else
        ''
      end
    end

    def vm_ware_error_message(result)
      result.present? ? result[:error] || '' : ''
    end

    def recommendation_service_log(data, activity)
      if data.key?(:error)
        case data[:error]
        when 'no_assigned_emails'
          activity.set_response("event_recommendation_service_no_email_error")
        when 'no_user'
          activity.set_response("event_recommendation_service_no_user")
        else
          activity.set_response("event_recommendation_service_error")
        end
        state = 'failure'
      else
        activity.set_response("event_recommendation_service_success")
        state = "success"
      end
    end

    def vm_ware_log_and_state(result, data, activity)
      ESLog.info "----result---#{result}------"
      ESLog.info "----data---#{data}------"
      if result[:status].eql?('failed')
        activity.set_response("event_#{data[:from]}_#{data[:action_name]}_error")
        state = 'failure'
      elsif result[:status].eql?('success')
        activity.set_response("event_#{data[:from]}_#{data[:action_name]}_success")
        state = 'success'
      end
      state
    end
  end
end
