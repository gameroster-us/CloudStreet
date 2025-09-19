class SecurityScanners::ScannerObjects::IamUser < Struct.new(:arn, :password_next_rotation, :user_name,:root_keys_present, :active_signing_certificates, :root_account_usage, :root_mfa_enabled, :password_expiry_7_days, :password_expiry_30_days, :password_expiry_45_days, :last_used_access_key, :last_used_password, :iam_user_unused, :access_key_30_days, :access_key_45_days, :access_key_90_days, :virtual_mfa_devices, :user_with_admin_Privileges, :canary_token_compliant, :policies_attached,:unnecessary_access_keys,:iam_user_login_profile, :iam_user_list_mfa_devices, :iam_user_access_keys_list, :iam_user_ssh_public_keys, :user_password_last_used)
  extend SecurityScanners::ScannerObjects::ObjectParser

  def scan(rule_sets, &block)
    rule_sets.each do |rule|
      if rule.has_key?("property")
        if rule["property"].eql?("ssh_public_keys") && iam_user_ssh_public_keys.present?
          ssh_keys_status = []
          iam_user_ssh_public_keys.each do |iam_user_ssh_public_key|
            status = eval(rule["evaluation_condition"]) rescue false
            ssh_keys_status << status
          end
          yield(rule) if ssh_keys_status.count(true) >= 1
        elsif rule["property"].eql?("access_keys_list") && iam_user_access_keys_list.present? 
          access_keys_status = []
          iam_user_access_keys_list.each do |iam_user_list_access_key|
            status = eval(rule["evaluation_condition"]) 
            access_keys_status << status
          end 
          yield(rule) if access_keys_status.count(true) >= 1 
        elsif rule["property"].eql?("access_keys_list_status") && iam_user_access_keys_list.present? 
          access_keys_status = []
          iam_user_access_keys_list.each do |iam_user_list_access_key|
            status = eval(rule["evaluation_condition"]) 
            access_keys_status << status
          end 
          yield(rule) if access_keys_status.count(true) > 1        
        elsif rule["property"].eql?("ssh_public_keys_list") && iam_user_ssh_public_keys.present? 
          public_keys_status = []
          iam_user_ssh_public_keys.each do |iam_user_ssh_public_key|
            status = eval(rule["evaluation_condition"]) 
            public_keys_status << status
          end 
          yield(rule) if public_keys_status.count(true) > 1
        elsif rule["property"].eql?("virtual_mfa_devices_check") && virtual_mfa_devices.present?
          virtual_mfa_devices.each do |virtual_mfa_device|
            status = eval(rule["evaluation_condition"]) rescue false
            yield(rule) if status
          end   
      end
      else
        status = eval(rule["evaluation_condition"]) rescue false
        yield(rule) if status
      end
    
    end   
  end

  class << self
      def create_new(object)
        root_keys_present, active_signing_certificates,root_account_usage,last_used_password,last_used_access_key, access_key_30_days, access_key_45_days, access_key_90_days = get_user_values(object)
        return new(
          object.arn,
          object.password_next_rotation,
          object.user_name,
          root_keys_present,
          active_signing_certificates,
          root_account_usage,
          object.user_name.eql?("<root_account>") && !object.mfa_active,
          false,
          false,
          false,
          last_used_access_key,
          last_used_password,
          object.password_last_used.blank? && !(object.access_key_1_active || object.access_key_2_active),
          access_key_30_days,
          access_key_45_days,
          access_key_90_days,
          object.try(:virtual_mfa_devices),
          user_with_admin_Privileges(object),
          false,
          false,
          false,
          object.login_profile,
          object.list_mfa_devices,
          object.access_keys_list,
          object.ssh_public_keys,
          object.try(:password_last_used)
      )
      end

      def get_user_values(object)
        root_keys_present = object.user_name.eql?("<root_account>") &&  (object.access_key_1_active || object.access_key_2_active)
        active_signing_certificates = object.user_name.eql?("<root_account>") && (object.cert_1_active || object.cert_2_active)
        root_account_usage = object.user_name.eql?("<root_account>") && ((Date.today - object.password_last_used.to_date).to_i) < 30
        password_last_used = (Date.today - object.password_last_used.to_date).to_i.abs if object.password_last_used
        password_last_changed = (Date.today - object.password_last_changed.to_date).to_i.abs  if object.password_last_changed
        last_used_password = object.password_enabled.eql?(true) && ((password_last_used || 0) > 90) || ((password_last_changed || 0) > 90)
        access_key_1_last_used_date = (Date.today - object.access_key_1_last_used_date.to_date).to_i.abs if object.access_key_1_last_used_date
        access_key_2_last_used_date = (Date.today - object.access_key_2_last_used_date.to_date).to_i.abs if object.access_key_2_last_used_date
        access_key_1_last_rotated = (Date.today - object.access_key_1_last_rotated.to_date).to_i.abs if object.access_key_1_last_rotated
        access_key_2_last_rotated = (Date.today - object.access_key_2_last_rotated.to_date).to_i.abs if object.access_key_2_last_rotated
        last_used_access_key = (object.access_key_1_active.eql?(true) || object.access_key_2_active.eql?(true)) && (((access_key_1_last_used_date || 0) > 90 || (access_key_2_last_used_date || 0) > 90 || (access_key_1_last_rotated || 0) > 90 || (access_key_2_last_rotated || 0) > 90))

        access_key1_30_days_check = access_key_1_last_rotated.present? ? (access_key_1_last_rotated > 30) : false
        access_key2_30_days_check = access_key_2_last_rotated.present? ? (access_key_2_last_rotated > 30) : false
        access_key1_less_than_45_days_check = access_key_1_last_rotated.present? ? (access_key_1_last_rotated < 45) : false
        access_key2_less_than_45_days_check = access_key_2_last_rotated.present? ? (access_key_2_last_rotated < 45) : false
        access_key_30_days = (access_key1_30_days_check || access_key2_30_days_check) && ( access_key1_less_than_45_days_check || access_key2_less_than_45_days_check)

        access_key1_45_days_check = access_key_1_last_rotated.present? ? (access_key_1_last_rotated > 45) : false
        access_key2_45_days_check = access_key_2_last_rotated.present? ? (access_key_2_last_rotated > 45) : false
        access_key1_less_than_90_days_check = access_key_1_last_rotated.present? ? (access_key_1_last_rotated < 90) : false
        access_key2_less_than_90_days_check = access_key_2_last_rotated.present? ? (access_key_2_last_rotated < 90) : false
        access_key_45_days = (access_key1_45_days_check || access_key2_45_days_check) && (access_key1_less_than_90_days_check || access_key2_less_than_90_days_check)

        access_key_90_days = ((access_key_1_last_rotated.present? ? (access_key_1_last_rotated > 90) : false) || (access_key_2_last_rotated.present? ? (access_key_2_last_rotated > 90) : false))
        return root_keys_present, active_signing_certificates,root_account_usage,last_used_password,last_used_access_key, access_key_30_days,access_key_45_days,access_key_90_days
      end

      def user_with_admin_Privileges(object)
        return false if object.user_name.eql?("<root_account>")
        iam_policy_ids  = IamUserRolePolicy.where(iam_id: object.id).pluck(:policy_id)
        policy_names = AttachedPolicy.where(id: iam_policy_ids, aws_account_id: object.aws_account_id).pluck(:policy_name)
        policy_names.include?('AdministratorAccess') ? true : false
      end
  end

end
