module UserActivityInfoHelper

  def user_activity_description
    case self.action
    when 'event_env_backup'
      log_backup_event
    when 'create','create_subnet'
      if self.data[:environment_name].present?
        "Created #{self.controller.singularize} #{self.name} in #{self.data["environment_name"]} Environment"
      elsif ["vpcs", "ami_config_categories"].include?(self.controller)
        "Created #{module_mapper[self.controller]} #{self.name}"
      elsif self.data['group_name'].present? && self.data['script_name'].present?
        "Created script #{self.data['script_name']} in group #{self.data['group_name']}"
      elsif ["slack"].include?(self.controller)
        "Created Slack Channel #{name}"
      elsif controller == 'organisations' && child_organisation_name.present?
        "Created #{organisation_purpose} Organisation #{child_organisation_name}"
      elsif ["budgets"].include?(controller)
        "Created AWS Budget #{name}"
      elsif ["report_data_reprocessings"].include?(self.controller)
        provider_type = self.data['provider_type'] == 'Vm_ware' ? 'VMware' : self.data['provider_type'].humanize
        month = provider_type != 'GCP' ? "for #{self.data['reprocessing_month']}" : ''
        "#{provider_type} worker initiated for #{self.data['adapter_name']} #{month}"
      elsif controller.eql?('sa_recommendations')
        "Created #{data['provider']} Service Adviser Recommendation against #{ServiceAdviser::Helpers::Common::SERVICE_TYPE[data[:service_type]] || data[:service_type].try(:humanize)} | service(s) - #{self.name}"
      elsif self.controller == 'vm_ware_budgets'
        "Created VMware Budget #{self.name}"
      else
        "Created #{self.controller.singularize.humanize} #{self.name}"
      end
    when 'share_budget'
      provider_type = case self.controller
      when 'budgets'
        'AWS Budget'
      when 'vm_ware_budgets'
        'VMware Budget'
      else
        self.controller.singularize.humanize
      end
      "#{self.data[:shared_type].try(:capitalize)} #{provider_type} to Tenant"
    when 'share'
      if self.controller.eql?('custom_dashboards')
        "Shaing updated for #{self.controller.singularize.humanize} #{self.name}"
      else
        "Shared #{self.controller.singularize.humanize} #{self.name}"
      end
    when 'share_for_role'
      "Shared for role #{self.controller.singularize.humanize} #{self.name}"
    when 'activate'
      "Activated #{self.controller.singularize.humanize} #{self.name}"
    when 'update', 'edit_subnet'
      if self.controller == "ami_config_categories"
        "Updated #{module_mapper[self.controller]} #{self.name}"
      elsif self.data['script_name'].present?
        if self.data['is_delete_script']
          "Deleted script #{self.data['script_name']}"
        else
          "Updated script #{self.data['script_name']}"
        end
      elsif self.controller == "rds_configurations"
        "Updated #{module_mapper[self.controller]} of #{self.data['user_roles']}"
      elsif ["slack"].include?(self.controller)
        "Updated Slack Channel #{name}"
      elsif ["budgets"].include?(controller)
        "Updated AWS Budget #{name}"
      elsif self.controller == "adapters" && self.child_organisation_name.present?
        if name.present?
          "Shared Adapter(s)/Adapter Group(s) #{name} to #{organisation_purpose} Organisation #{child_organisation_name}"
        else
          "Unshared all Adapter(s)/Adapter Group(s) from #{organisation_purpose} Organisation #{child_organisation_name}"
        end
      elsif controller.eql?('sa_recommendations')
        "Updated #{data['provider']} Service Adviser Recommendation, service type :  #{ServiceAdviser::Helpers::Common::SERVICE_TYPE[data[:service_type]] || data[:service_type].try(:humanize)} | Service Name : #{self.name}"
      elsif self.controller == 'vm_ware_budgets'
        "Updated VMware Budget #{self.name}"
      else
        "Updated #{self.controller.singularize.humanize} #{self.name}"
      end
    when 'bulk_update'
      "Updated #{data['provider']} Service Adviser Recommendation Service's: #{self.name}" if controller.eql?('sa_recommendations')
    when 'remove','destroy', 'archive_tag', 'delete_security_group', 'delete_subnet'
      if self.controller == "ami_config_categories"
        "Deleted #{module_mapper[self.controller]} #{self.name}"
      elsif ["slack"].include?(self.controller)
        "Deleted Slack Channel #{name}"
      elsif ["budgets"].include?(controller)
        "Deleted AWS Budget #{name}"
      elsif self.controller.eql?('custom_dashboards')
        "Unshared and Deleted #{self.controller.singularize.humanize} #{self.name}"
      elsif controller.eql?('sa_recommendations')
        "Deleted #{data['provider']} Service Adviser Recommendation, service type : #{ServiceAdviser::Helpers::Common::SERVICE_TYPE[data[:service_type]] || data[:service_type].try(:humanize)} | service Name : #{self.name}"
      elsif self.controller == 'vm_ware_budgets'
        "Deleted VMware Budget #{self.name}"
      else
        "Deleted #{self.controller.singularize.humanize} #{self.name}"
      end
    when 'start'
      if self.controller.eql?('service_managers')
        "Started Service #{self.name}"
      else
        "Started #{self.controller.singularize.humanize} #{self.name}"
      end
    when 'stop'
      if self.controller.eql?('service_managers')
        "Stopped Service #{self.name}"
      else
        "Stopped #{self.controller.singularize.humanize} #{self.name}"
      end
    when 'terminate'
      if self.data[:environment_name].present?
        "Terminated #{self.controller.singularize} #{self.name} from #{self.data["environment_name"]} Environment"
      else
        "Terminated #{self.controller.singularize.humanize} #{self.name}"
      end
    when 'attach'
      "Attached #{self.controller.singularize.humanize} #{self.name}"
    when 'detach'
      "Detached #{self.controller.singularize.humanize} #{self.name}"
    when 'provision'
      "Provisioned #{self.controller.singularize.humanize} #{self.name}"
    when "provision_sync_services"
      "Provisioned #{self.name} Environment from unallocated build page"
    when 'archive_vpc'
      "Deleted #{self.controller.singularize.upcase} #{self.name}"
    when "create_key_pair"
      "Created #{self.name} Keypair"
    when "destroy_key_pair"
      "Deleted #{self.name} Keypair"
    when 'create_s3_bucket'
      "Created s3 bucket #{self.name}"
    when 'enable_disable_region'
      "Updated Regions #{self.name}"
    when 'delete_s3_bucket'
      "Deleted s3 bucket #{self.name}"
    when 'update_bucket_acl'
      p self
      "Updated s3 bucket permissions for #{self.name}"
    when 'init'
      "Updated from #{self.data[:old_version]} to #{self.data[:new_version]}"
    when 'soe_script_sync_complete'
      begin
        res = "SOE Scripts Synchronization completed with #{self.data[:success_count]} success and #{self.data[:failure_count]} failures. "
        res+= "#{self.data[:success_list].join(',')} sources completed successfully. " unless self.data[:success_list].blank?
        res+= "#{self.data[:failure_list].join(',')} sources failed." unless self.data[:failure_list].blank?
        res
      rescue Exception => e
        ""
      end
    when 'refetch_iam_adapters'
      "Refetched IAM Role based adapters"
    when 'create_generic_template'
      "Created Generic #{self.controller.singularize.humanize} #{self.name}"
    when 'update_generic'
      "Updated Generic #{self.controller.singularize.humanize} #{self.name}"
    when 'provision_generic_template'
      "Provisioned Generic #{self.controller.singularize.humanize} #{self.name}"
    when 'run_task_now'
      if self.data['dry_run']
        "#{self.controller.singularize.humanize} #{self.name} Execution has been started using Dry Run action"
      else
        "#{self.controller.singularize.humanize} #{self.name} Execution has been started using Run Now action"
      end
    when 'task_execution'
        "#{self.type} - #{self.name} Execution has Started"
    when  'task_execution_completed'
        "#{self.name} Execution has completed"
    when 'sync_start'
      "Started #{self.controller.singularize.humanize} for #{self.name} Adapter"
    when 'sync_complete'
      "Completed #{self.controller.singularize.humanize} for #{self.name} Adapter"
    when 'sync_failed'
      "#{self.controller.singularize.humanize} for #{self.name} Adapter Failed"
    when 'remove_from_management'
      "Removed #{self.controller.singularize.humanize} #{self.name} from management"
    when 'update_service_names'
      "Changed #{self.controller.singularize.humanize} settings"
    when 'invite'
      "Invited #{self.controller.singularize.humanize}"
    when 'remove_services'
      "Removed service #{self.name} from #{self.controller.singularize.humanize}"
    when 'move_services'
      "Moved service #{self.name} from #{self.controller.singularize.humanize}"
    when 'copy_template_from_revision'
      if self.data[:environment_name].present?
        "Copied #{self.controller.singularize.humanize} #{self.name} from Environment #{self.data["environment_name"]}"
      elsif self.data[:template_name].present?
        "Copied #{self.controller.singularize.humanize} #{self.name} from Template #{self.data["template_name"]}"
      end
    when "terminate_services_removed_from_provider"
      "Environment #{self.name} started using Make healthy option"
    when "update_access"
      if self.controller == "vpcs"
        "Updated access of #{module_mapper[self.controller]} #{self.name} to #{self.data["user_roles"]}"
      elsif self.data["user_roles"].present?
        "Updated access of #{self.controller.singularize.humanize} #{self.name} to #{self.data["user_roles"]}"
      else
        "Removed access of #{self.controller.singularize.humanize} #{self.name}"
      end
    when 'add_member'
      "Added member #{self.name} to #{self.controller.singularize.humanize} #{self.data["user_roles"]}"
    when 'remove_member'
      "Removed member #{self.data["manage_username"]} from #{self.controller.singularize.humanize} #{self.name}"
    when 'delete_invited_user'
      "Deleted invited user #{self.data['manage_username']} from #{self.controller.singularize.humanize}"
    when "enable_disable_member"
      "#{self.data[:enable_disable_status]} #{self.controller.singularize.humanize} #{self.data['manage_username']}"
    when 'assign_tenants'
      "Assigned #{self.controller.singularize.humanize} #{self.data['manage_username']} to tenant #{self.name}"
    when 'remove_tenants'
      "Removed #{self.controller.singularize.humanize} #{self.data['manage_username']} from tenant #{self.name}"
    when 'copy'
      if self.data['script_name'].present?
        "Copied SOE script #{self.data['script_name']} from #{self.controller.singularize} #{self.data['group_name']}"
      elsif self.name.present?
        "Copied #{self.controller.singularize.humanize} #{self.name}"
      else
        "Copied #{self.controller.singularize.humanize} #{self.data['group_name']}"
      end
    when 'destroy_all_scripts'
      "Destroyed all #{module_mapper[self.controller]}"
    when 'update_general_setting'
      'Updated General Settings'
    when 'service_adviser_configuration'
      "Updated #{self.controller.singularize.humanize}"
    when 'create_or_update'
      "Updated SSO Configuration."
    when 'sync_owned_images'
      "Fetching Private AMIs."
    when 'update_tenant_permission'
      "Updated tenant permission of users #{self.data['manage_username']} to roles #{self.data['user_roles']}"
    when 'scan'
      "Scanned #{self.controller.singularize.humanize}"
    when 'get_scan_summery_csv', 'update_service_tag_key'
      "#{self.action.singularize.humanize}"
    when 'get_recommendation_csv'
      "Exported service data in CSV"
    when 'event_pause_resume'
      if self.data[:enable]
        "Resume #{self.data['name']}"
      else
        "Paused #{self.data['name']}"
      end
    when 'authorize_port_range_outbound'
      "Added outbound rule in security group #{self.data['name']}"
    when 'authorize_port_range_inbound'
      "Added inbound rule in security group #{self.data['name']}"
    when 'revoke_port_range_inbound'
      "Removed inbound rule from security group #{self.data['name']}"
    when 'revoke_port_range_outbound'
      "Removed outbound rule from security group #{self.data['name']}"
    when 'delete_service_group'
      "Deleted #{self.data['name']} from Service Group"
    when 'schedule_backup'
      "Scheduled #{self.controller.singularize.humanize} event #{self.name}"
    when 'update_resize_instances'
      "Service(s) Opt-Out from task #{self.name}"
    when 'authentication'
      if self.data[:already_authenticate]
        "Already Created Slack Workspace #{self.name}"
      else
        "Created Slack Workspace #{self.name}"
      end
    when 'workspace_delete'
      "Deleted Slack Workspace #{self.name}"
    when 'update_channel_configuration'
      "Updated Slack Channel Configuration #{self.name}"
    when 'remove_adapter'
      "Removed Adapter #{name} from #{organisation_purpose} Organisation #{child_organisation_name}"
    when 'activate', 'deactive'
      if controller == 'organisations' && action == 'activate'
        "Activated #{organisation_purpose} Organisation #{name}"
      elsif controller == 'organisations' && action == 'deactive'
        "Deactivated #{organisation_purpose} Organisation #{name}"
      end
    when 'destroy_all_adapters'
      "Deleted All Adapters"
    when 'update_teams_channel_configuration'
      "Updated Teams Configuration #{self.name}"
    when 'teams_workspace_delete'
      "Deleted Teams Workspace #{self.name}"
    when 'teams_authentication'
      if self.data[:already_authenticate]
        "Already Created Teams Workspace #{self.name}"
      else
        "Created Teams Workspace #{self.name}"
      end
    when 'service_now_authentication'
      "Created ServiceNow Workspace #{self.name}"
    when 'update_service_now_configuration'
      "Updated ServiceNow configuration #{self.name}"
    when 'service_now_workspace_delete'
      "Deleted ServiceNow Workspace #{self.name}"
    when 'service_now_workspace_update'
      "Updated ServiceNow Workspace #{self.name}"
    when "delete_all_workspaces"
      "Deleted All Workspaces"
    when "reset_password"
      "Updated Password"
    when 'update_saml_user_details', 'update_saml_settings'
      if self[:data].present? && self[:data][:saml_settings_user].present?
        "Updated #{self[:data][:saml_settings_user]}"
      end
    when 'active_dashboard'
      "Dashboard Activated"
    when 'activate_all_user'
      'Dashboard Activated for Organisation'
    when 'set_trial_days'
      "Trial period updated for organisation #{self.name}"
    when 'enable_child'
      "Child organisation access #{child_org_access.downcase} for organisation #{self.name}"
    when 'make_permanent'
      "Organisation #{self.name} converted to a permanent organisation"
    when 'saml_login'
      if self.controller == 'sessions' && self.data['status'] == 'success'
        "SSO session login successfully for the user #{self.try(:username)}"
      else
        "SSO login attempt failed for user #{self.try(:username)}"
      end
    when 'create_notification'
      "Created/Updated #{self.name} #{self.controller.singularize.humanize} Email Notification"
    when 'delete_notification'
      "Deleted #{self.name} #{self.controller.singularize.humanize} Email Notification"
    when 'create_service_tags_on_provider'
      "Updated tags for resource name #{self.data[:resource_name]}."
    when 'update_resource_tags'
      "Updated tags for resource name #{self.data[:resource_name]}."
    when 'process_report'
      billing_data_not_found = self['data']['billing_data_not_found']
      generated_type = self[:data][:is_slide] ? 'Slide' : 'Excel'
      metric = self[:data][:metric].gsub('_', ' ').titleize
      if billing_data_not_found
        "We're sorry, there was an issue generating the #{self[:data][:provider_type].upcase} export report for the Billing adapter #{self[:data][:adapter_name]}. Please contact the administrator for assistance."
      else
        "Generated #{self[:data][:provider_type].upcase} Report #{generated_type} for the Billing adapter #{self[:data][:adapter_name]} and Metric #{metric}"
      end
    when 'reload_vpc'
      "Reload VPC #{self.name}"
    when 'reboot'
      "Reboot Service #{self.name}"
    when 'tenant_update', 'group_update'
      "Updated budget #{self[:data][:name]} due to change in group or updation in tenant."
    end
  end

end
