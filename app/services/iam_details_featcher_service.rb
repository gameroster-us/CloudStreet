class IamDetailsFeatcherService < CloudStreetService
  extend SecurityScanHelper
  class << self

    def get_uniq_account_iam_data
      IamDetailsFeatcherService.get_uniq_accounts("add_iam_user_details")
    end

    def add_iam_user_details(adapter)
      IamUser.where(aws_account_id: adapter.aws_account_id).delete_all
      IamUserRolePolicy.where(aws_account_id: adapter.aws_account_id,iam_type: "IamUser").delete_all
      Policy.where(aws_account_id: adapter.aws_account_id).delete_all
      CSLogger.info "==== Fetching IAM Users from adapter #{adapter.name}==for account #{adapter.aws_account_id}======"
      object = if adapter.is_us_gov.eql?("true") || adapter.is_us_gov.eql?(true)
                AWSSdkWrappers::Iam::Client.new(adapter, "us-gov-east-1")
               else
                AWSSdkWrappers::Iam::Client.new(adapter, "us-east-1")
               end
      client = object.client
      create_client_and_import_iam_user_data(adapter, adapter.aws_account_id,client)
      iam_users_details = IamUser.where(aws_account_id: adapter.aws_account_id)
      iam_users_details.each do |iam_user|
       unless iam_user.user_name.eql?("<root_account>")
        iam_user.ssh_public_keys = get_ssh_public_keys(client, iam_user.user_name)
        iam_user.access_keys_list = get_access_keys(client, iam_user.user_name).as_json
        iam_user.login_profile = get_login_profile(client, iam_user.user_name).to_h.as_json # Modified line while changing aws-sdk version
        iam_user.list_mfa_devices = get_list_mfa_devices(client,iam_user.user_name)
       end
      end
      import_iam_user_details(iam_users_details)
      iam_group_details_fetcher(adapter, adapter.aws_account_id,client)
      iam_group_details = IamGroup.where(aws_account_id: adapter.aws_account_id)
      iam_group_details.each do |iam_group|
        iam_group.users = get_group_details(client, iam_group.group_name).as_json
        iam_group.list_group_policies = get_group_policies(client, iam_group.group_name).as_json
      end
     import_iam_group_details(iam_group_details)
     # update SecurityScanStorage data for IamUser
     SecurityScanner.scan_service_by_service_type('IamUser', adapter)
    end

    def create_client_and_import_iam_user_data(adapter, aws_account_id, client)
      begin
        ProviderWrappers::AWS.retry_on_timeout{
          @iam_users = client.list_users.users.as_json
        }
        user_id_map = IamUser.where(aws_account_id: aws_account_id).pluck(:arn, :id).to_h
        @iam_users.each{  |iam_user| iam_user[:aws_account_id] =  aws_account_id }
        @iam_users.each{  |iam_user| iam_user[:adapter_id] =  adapter.id }
        @iam_users.each { |iam_user| (iam_user[:id] = user_id_map[iam_user["arn"]] || SecureRandom.uuid )} if user_id_map.present?
        IamUser.import @iam_users, on_duplicate_key_update: {conflict_target: [:id], columns: [:path, :user_name, :adapter_id, :arn, :create_date, :password_last_used,:permissions_boundary, :tags]}
        generate_and_update_iam_user_credential_report(client, aws_account_id, adapter)
      rescue Exception => e
        CSLogger.error "====Exception=in===create_client_and_import_iam_user_data==#{e.message}==for adapter==#{adapter.name}==="
      end
    end

    def generate_and_update_iam_user_credential_report(client, aws_account_id, adapter)
      begin
        ProviderWrappers::AWS.retry_on_timeout{
          client.generate_credential_report
          @report = client.get_credential_report.content
        }
        iam_users_array = process_csv_data(@report, aws_account_id, adapter)
        virtual_mfa_device_data = get_root_account_hardware_mfa_details(client).as_json
        iam_users_array.each { |iam_user| iam_user['virtual_mfa_devices'] = iam_user['user_name'].eql?("<root_account>") ? virtual_mfa_device_data : nil } # Modified line while changing aws-sdk version
        IamUser.import iam_users_array, on_duplicate_key_update: {conflict_target: [:id], columns: [:path, :user_name, :password_enabled, :password_last_used, :password_last_changed,:password_next_rotation,:mfa_active,:access_key_1_active,:access_key_1_last_rotated,:access_key_1_last_used_date,:access_key_1_last_used_region,:access_key_1_last_used_service,:access_key_2_active,:access_key_2_last_rotated,:access_key_2_last_used_date,:access_key_2_last_used_region,:access_key_2_last_used_service,:cert_1_active,:cert_1_last_rotated,:cert_2_active,:cert_2_last_rotated, :aws_account_id, :adapter_id, :virtual_mfa_devices]}
      rescue Exception => e
        CSLogger.error "====Exception=in===generate_and_update_iam_user_credential_report==#{e.message}==for adapter==#{adapter.name}==="
      end
    end

    def get_root_account_hardware_mfa_details(client)
        begin
          resp = client.list_virtual_mfa_devices.try(:[],'virtual_mfa_devices')
        rescue Exception => e
          CSLogger.error "====Exception=in====get_root_account_hardware_mfa_details==#{e.message}======="
          return []
        end   
    end  

    def get_ssh_public_keys(client, user_name)
      begin
        return client.list_ssh_public_keys({user_name: user_name}).try(:ssh_public_keys)
      rescue Exception => e
        CSLogger.error "====Exception=in====get_ssh_public_keys==#{e.message}======="
        return []
      end
    end

    def get_access_keys(client, user_name)
      begin
        return client.list_access_keys({user_name: user_name}).try(:access_key_metadata)
      rescue Exception => e
        CSLogger.error "====Exception=in====get_access_keys==#{e.message}======="
        return []
      end
    end

    def get_login_profile(client, user_name)
      begin
        resp = client.get_login_profile({user_name: user_name})
      rescue Aws::IAM::Errors::NoSuchEntity => e
        CSLogger.error "====Exception=in====get_login_profile==#{e.message}======="
        return {}
      rescue Exception => e
        CSLogger.error "====Exception=in====get_login_profile==#{e.message}======="
        return nil
      end
    end

    def get_list_mfa_devices(client, user_name)
      begin
        resp = client.list_mfa_devices({user_name: user_name}).try(:mfa_devices)
      rescue Exception => e
        CSLogger.error "====Exception=in====get_list_mfa_devices==#{e.message}======="
        return nil
      end
    end

    def import_iam_user_details(iam_users_details)
      return if iam_users_details.blank?
      IamUser.import iam_users_details.to_a, on_duplicate_key_update: {conflict_target: [:id], columns: [:ssh_public_keys,:access_keys_list,:login_profile, :list_mfa_devices ]} 
    end

    def iam_group_details_fetcher(adapter, aws_account_id, client)
      IamGroup.where(aws_account_id: adapter.aws_account_id).delete_all
      begin
        iam_groups = client.list_groups({}).groups.as_json 
      rescue Exception => e
        CSLogger.error "====Exception=in====iam_group_details_fetcher==#{e.message}====for adapter==#{adapter.name}==="
      end
      return if iam_groups.blank?
      group_id_map = IamGroup.pluck(:arn, :id).to_h
      iam_groups.each{  |iam_group| iam_group[:aws_account_id] =  aws_account_id }
      iam_groups.each{  |iam_group| iam_group[:adapter_id] =  adapter.id }
      iam_groups.each{  |iam_group| (iam_group[:id] = (group_id_map[iam_group["arn"]] || SecureRandom.uuid) )} if group_id_map.present?
      IamGroup.import iam_groups.to_a, on_duplicate_key_update: {conflict_target: [:id], columns: [ :path, :adapter_id, :account_id, :group_id , :arn, :group_name,:create_date,:aws_account_id, :created_at, :updated_at]}
    end 

    def get_group_details(client, group_name)
      begin
        resp = client.get_group({group_name: group_name}).try(:users)
      rescue Exception => e
        CSLogger.error "====Exception=in====get_group_details==#{e.message}======="
        return []
      end
    end

    def get_group_policies(client, group_name)
      begin
        resp = client.list_group_policies({group_name: group_name}).try(:policy_names)
      rescue Exception => e
        CSLogger.error "====Exception=in====get_group_policies==#{e.message}======="
        return []
      end
   end

    def import_iam_group_details(iam_group_details)
      return if iam_group_details.blank?
      IamGroup.import iam_group_details.to_a, on_duplicate_key_update: {conflict_target: [:id], columns: [:users,:list_group_policies]} 
    end 

    def process_csv_data(report, aws_account_id,adapter)
      iam_users_array = []
      csv = CSV.parse(report, :headers => true, :encoding => 'ISO-8859-1')
      csv.each do |row|
        iam_user = IamUser.find_or_create_by(arn: row["arn"])
        row["user_name"] = row["user"]
        row["aws_account_id"] = aws_account_id
        row["adapter_id"] = adapter.id
        row.delete(0)
        row.delete(1)
        row["password_enabled"] = parse_blank_data(row["password_enabled"])
        row["password_last_used"] = parse_blank_data(row["password_last_used"])
        row["password_last_changed"] = parse_blank_data(row["password_last_changed"])
        row["password_next_rotation"] = parse_blank_data(row["password_next_rotation"])
        row["access_key_1_last_rotated"] = parse_blank_data(row["access_key_1_last_rotated"])
        row["access_key_1_last_used_date"] = parse_blank_data(row["access_key_1_last_used_date"])
        row["access_key_2_last_rotated"] = parse_blank_data(row["access_key_2_last_rotated"])
        row["access_key_2_last_used_date"] = parse_blank_data(row["access_key_2_last_used_date"])
        row["cert_1_last_rotated"] = parse_blank_data(row["cert_1_last_rotated"])
        row["cert_2_last_rotated"] = parse_blank_data(row["cert_2_last_rotated"])
        iam_users_array << row.to_hash.merge("id" => iam_user.as_json["id"])
      end
      return iam_users_array
    end

    def parse_blank_data(value)
      if value.eql?("N/A") || value.eql?("not_supported") || value.eql?("no_information")
        return nil
      else
        return value
      end
    end
  end
end
