module Backupable
  class BackupWorker
    include Sidekiq::Worker
    sidekiq_options queue: :task_queue, :retry => false, backtrace: true

    def perform(options)
        data = {user_activity_id: options["activity_id"]}
        action_owner_details = Task.find(options["task_id"])
        if action_owner_details
            data.merge!(action_owner_details: action_owner_details)
        	service =  set_backup_data(options)
            create_backup(options,service)
        end
        rescue Fog::AWS::Compute::Error => e
            ESLog.error "===========In Rescue ==Fog::AWS::Compute::Error==for task id===#{options[:task_id]}=========="
            ESLog.error "===========#{e.message}=======#{e.class}=====#{e.backtrace}========="
            data.merge!(response_key: "event_service_backup_error",resource_error_message: e.message)
            set_activity_log(service,data)
            data.key?(:action_owner_details) ? action_owner_details.set_progress_data("failure") : nil
        rescue Fog::AWS::RDS::NotFound,Fog::AWS::Compute::NotFound => e
            ESLog.error "===========In Rescue ====for task id===#{options[:task_id]}=========="
            ESLog.error "===========#{e.message}=======#{e.class}=====#{e.backtrace}========="
            data.merge!(response_key: "event_service_backup_error",resource_error_message: "Remote service not found")
            set_activity_log(service,data)
            data.key?(:action_owner_details) ? action_owner_details.set_progress_data("failure") : nil
        rescue Fog::AWS::RDS::Error,Fog::Compute::AWS::Error => e
            data.merge!(response_key: "event_service_backup_error",resource_error_message: e.message)
            set_activity_log(service,data)
            data.key?(:action_owner_details) ? action_owner_details.set_progress_data("failure") : nil
        rescue ActiveRecord::RecordNotFound => exception
            ESLog.error "#{self.class}: #{exception.class} : #{exception.message}"
            data.merge!(response_key: "event_service_backup_error",resource_error_message: exception.message)
            set_activity_log(nil,data) 
        rescue Exception => exception
            ESLog.error "#{self.class}: #{exception.class} : #{exception.message} : #{exception.backtrace}"
            data.merge!(resource_error_message: exception.message,response_key: "event_service_backup_error")
            set_activity_log(service,data) 
            data.key?(:action_owner_details) ? action_owner_details.set_progress_data("failure") : nil
        raise exception
        ensure
            UserActivity.update_activity(options[:task_id],options[:activity_id])
    end

    def set_activity_log(service,data)    
        activity_options = {
            module_name: "Event Scheduler",
            action_name: "backup",
            action_status: "Success",
            action_message: "Event Run Successfully",
            resource_owner: "AWS",
            resource_error_message: data[:resource_error_message]
        }     
        activity = UserActivityLog.init_activity(service,activity_options,data) if data[:user_activity_id].present?
    end

    def set_backup_data(options)
        options.symbolize_keys!
        ESLog.info "Started #{self.class} #{options[:target_description]}"
        service = options[:service_klass].constantize.find(options[:service_id])
        service.user = User.find(options[:user_id])
        return service
    end

    def create_backup(options,service)
        action_owner_details = Task.find(options[:task_id])
        ESLog.info "============in backup worker ====for==#{service.try(:provider_id)}=============="
        policy = BackupPolicy.find(options[:policy_id])
        data = {resource_previous_state: service.state, action_owner_details: action_owner_details,user_activity_id: options[:activity_id],resource_destination_adapter_name: policy.adapter.present? ? policy.adapter.try(:name) : nil}
        options = service.create_service_backup(options) unless service.type.eql?("Snapshots::AWS")
        can_proceed_backup, remote_service = service.can_proceed_backup?(options)
        if can_proceed_backup
            service.modify_image_backup(options) if options[:bunker_option]
            set_multiple_log_for_backup(service,data,"event_service_backup_shared_success") if options[:bunker_option]
            options = service.copy_backup_action(options)
            set_multiple_log_for_backup(service,data,"event_service_backup_copy_success") if options[:bunker_option]
            final_remote_backup = service.backup_completed?(options)
            ESLog.info "===in backup worker==for task #{options[:task_id]}==#{final_remote_backup}===========#{final_remote_backup.try(:ready)}"
            if final_remote_backup && final_remote_backup.ready?
                ESLog.info "===========final_remote_backup is ready=======for #{service.try(:provider_id)}======="
                service.post_backup_action(options)
                set_multiple_log_for_backup(service,data,"event_service_backup_delete_success") if options[:bunker_option] && options[:source_copy]
                set_multiple_log_for_backup(service,data,"event_service_backup_success")
                action_owner_details.set_progress_data("success")
            elsif !remote_service.present?
                ESLog.info "==in elsif===task id ====== #{options[:task_id]}======remote_service is==== #{remote_service}=============="
                data.merge!(resource_error_message: "Remote service not found")
                set_multiple_log_for_backup(service,data,"event_service_backup_error")
                action_owner_details.set_progress_data("failure")
            else
                ESLog.info "==in else====task id ====== #{options[:task_id]}====="
                data.merge!(resource_error_message: "Something went wrong in AWS")
                set_multiple_log_for_backup(service,data,"event_service_backup_error")
                action_owner_details.set_progress_data("failure")
            end
        end
        ESLog.info "Finished #{self.class} #{options[:target_description]}"
    end

    def set_multiple_log_for_backup(service,data,msg)
        data.merge!(response_key: msg)
        set_activity_log(service,data)
    end
  end
end
