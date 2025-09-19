module SecurityScanners::IamUser

  def start_scanning
    return if @adapter.adapter_purpose.eql?("backup")
    return unless @region.code.eql?('us-east-1')
    iam_users = get_iam_user
    # return if iam_users.blank?
    new_iam_user = []
    SecurityScanners::ScannerObjects::IamUser.parse(iam_users) do |iam_user|
      if !iam_user.user_name.eql?("<root_account>")
        iam_user_pwd_expiry = password_expiry(iam_user)
        iam_user.password_expiry_7_days = iam_user_pwd_expiry[:password_expiry_7_days] || false
        iam_user.password_expiry_30_days = iam_user_pwd_expiry[:password_expiry_30_days] || false
        iam_user.password_expiry_45_days = iam_user_pwd_expiry[:password_expiry_45_days] || false
        canary_token_compliant, policies_attached,unnecessary_access_keys = policy_status(iam_user)
        iam_user.canary_token_compliant = canary_token_compliant
        iam_user.policies_attached = policies_attached
        iam_user.unnecessary_access_keys  = unnecessary_access_keys
      end
      new_iam_user << iam_user
    end
    rule_sets = parse_scanning_rule_conditions
    new_iam_user.each do |iam_user|
      threats = []
      iam_user.scan(rule_sets) do |threat|
        if threat.present?
          threats << threat
        end
      end
      prepare_threats_to_import(iam_user, threats) if threats.present?
    end
    clear_and_update_scan_report
  end

  def parse_condition(condition)
    operator = SecurityScanner::OPERATOR_MAP[condition[1]]
    case condition[1]
    when 'containAtLeastOneOf','includes','containNoneOf'
     "#{condition[2]}.#{operator}(#{condition[0]})"
    when 'notEmpty'
     "!#{condition[0]}.#{operator}"
    when 'datePriorTo'
         "Date.parse(#{condition[2]}) #{operator} Date.parse(#{condition[0]})"
    when 'isBlank?'
     "#{condition[0]}.#{operator}"
    when 'endsWith?'
     "(#{condition[0]}).#{operator}(#{condition[2]})" 
    else
     "#{condition[0]} #{operator} #{condition[2]}"
    end
  end

  def get_iam_user
    iam_user = IamUser.where(aws_account_id: @adapter.aws_account_id)
    return iam_user.to_a
  end
  
  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: object.arn,
        service_name: object.user_name,
        service_type: "IamUser",
        category: category,
        state: 'active',
        scan_status: threat['level'],
        scan_details: threat['description'],
        scan_details_desc: threat['description_detail'],
        CS_rule_id: threat["CS_rule_id"],
        rule_type: threat["type"],
        environments: [],
        created_at: Time.now,
        updated_at: Time.now
      })
    end
  end

  def password_expiry(iam_user)
    return {password_expiry: false} if iam_user.password_next_rotation.blank?
    passord_days_old = (iam_user.password_next_rotation.to_date - Date.today).to_i
    return {password_expiry: false}  if passord_days_old.negative?
    if  iam_user.password_next_rotation && ( passord_days_old >= 1) && (passord_days_old <= 7)
      return {password_expiry_7_days: true}
    elsif passord_days_old && (passord_days_old > 7) && (passord_days_old <= 30)
      return {password_expiry_30_days: true}
    elsif passord_days_old && (passord_days_old > 30) && (passord_days_old <= 45)
      return {password_expiry_45_days: true}
    else
      return {password_expiry: false}
    end
  end

  def policy_status(iam_user)
    iam_user_obj = IamUser.find_by(arn: iam_user.arn)
    iam_policy_ids  = IamUserRolePolicy.where(iam_id: iam_user_obj.id).pluck(:policy_id)
    policy_names = AttachedPolicy.where(id: iam_policy_ids).pluck(:policy_name)
    inline_names = InlinePolicy.where(id: iam_policy_ids).pluck(:policy_name)
    canary_token_compliant = policy_names.blank? && inline_names.blank? && (iam_user_obj.password_enabled.eql?(false) && iam_user_obj.password_last_used.blank?) && (iam_user_obj.access_key_1_active.eql?(true) || iam_user_obj.access_key_2_active.eql?(true))
    policies_attached = AttachedPolicy.where(id: iam_policy_ids).pluck(:policy_name).present?
    unnecessary_access_keys = (iam_user_obj.create_date.to_date.eql?(iam_user_obj.access_key_1_last_rotated.to_date) && iam_user_obj.access_key_1_last_used_date.blank?) rescue false
    return canary_token_compliant, policies_attached, unnecessary_access_keys
  end

end
