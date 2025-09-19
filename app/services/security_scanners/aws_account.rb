module SecurityScanners::AWSAccount

  def start_scanning
    return if @adapter.adapter_purpose.eql?("backup") || !@region.code.eql?('us-east-1')

    aws_accounts = get_aws_account
    ec2_instance_count = {}
    rds_instances_count = {}
    iam_user_count = {}
    iam_policy_support_check = {}
    iam_policy_access_check = {}
    iam_role_exists = {}

    if aws_accounts.present?
      aws_accounts.each do |aws_account|
        ec2_instance_count.merge!({aws_account.aws_account_id =>  get_server_count(aws_account.aws_account_id)})
        rds_instances_count.merge!({aws_account.aws_account_id =>  get_rds_insctance_count})
        iam_user_count.merge!({aws_account.aws_account_id => get_iam_user_count(aws_account.aws_account_id) })
        admin_policies, master_manger_policies = get_iam_policies(aws_account.aws_account_id)
        iam_policy_support_check.merge!({aws_account.aws_account_id => get_iam_policy_support(aws_account.aws_account_id) })
        iam_policy_access_check.merge!({aws_account.aws_account_id =>  admin_policies })
        iam_role_exists.merge!({aws_account.aws_account_id =>  master_manger_policies })
      end 
    end

    new_aws_account = []
    SecurityScanners::ScannerObjects::AWSAccount.parse(aws_accounts) do |aws_account|
      aws_account.server_count = ec2_instance_count[aws_account.aws_account_id]
      aws_account.rds_instance_count = rds_instances_count[aws_account.aws_account_id]
      aws_account.is_support_role = iam_policy_support_check[aws_account.aws_account_id]
      aws_account.is_full_administrative_privileges = iam_policy_access_check[aws_account.aws_account_id]
      aws_account.iam_users_count = iam_user_count[aws_account.aws_account_id]
      aws_account.iam_policy_check = iam_role_exists[aws_account.aws_account_id]
      new_aws_account << aws_account
    end
    rule_sets = parse_scanning_rule_conditions
    new_aws_account.each do |aws_account|
      threats = []
      aws_account.scan(rule_sets) do |threat|
        if threat.present?
          if ((aws_account.is_full_administrative_privileges.present?) && (threat['property'].eql?'full_administrative_privileges'))
            threat['description_detail'] = threat['description_detail'] + " Policies are  #{(aws_account.is_full_administrative_privileges).join(', ')}" if threat['description_detail'].present?
          end
          threats << threat
        end
      end
      prepare_threats_to_import(aws_account, threats) if threats.present?
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
    else
      "#{condition[0]} #{operator} #{condition[2]}"
    end
  end

  def get_aws_account
    aws_account = AWSAccount.where(aws_account_id: @adapter.aws_account_id)
    aws_account.to_a
  end

  def get_server_count(aws_account_id)
    Services::Compute::Server::AWS.where(adapter_id: @adapter.id, state: "running").count 
  end

  def get_rds_insctance_count
   Services::Database::Rds::AWS.where(adapter_id: @adapter.id, state: "running").count 
  end


  def get_iam_user_count(aws_account_id)
    IamUser.where("aws_account_id = ? AND adapter_id = ? AND user_name <> '<root_account>'", aws_account_id, @adapter.id).count
  end
  
  def get_iam_policy_support(aws_account_id)
    iam_policy_ids = IamUserRolePolicy.aws_account_iam_roles(aws_account_id).pluck(:policy_id)
    iam_policy_arn = Policy.where(id: iam_policy_ids, aws_account_id: aws_account_id, type: "AttachedPolicy").pluck(:policy_arn)
    return if iam_policy_arn.blank?

    iam_policy_arn.any? {|iam_policy_arn| iam_policy_arn.eql?("arn:aws:iam::aws:policy/AWSSupportAccess")}
  end

  def get_iam_policies(aws_account_id)
    iam_policies = Policy.where(aws_account_id: aws_account_id).where.not(policy_document: nil)
    return if iam_policies.blank?

    arr_iam_policies = []
    master_manger_policies = []
    iam_policies.each do |iam_policy|
      policy_doc = iam_policy.policy_document
      decoded_policy_doc = policy_doc.present? ? JSON.parse(CGI.unescape(policy_doc)) : []
      policy_statements = decoded_policy_doc['Statement'] if decoded_policy_doc.present?
      next if policy_statements.blank?

      if policy_statements.is_a?(Array)
        policy_statements.each do |policy_statement|
          admin_policies = check_administrative_privileges_for_policy(policy_statement)
          master_manger_policies = check_master_manager_policy_role(policy_statement)
          arr_iam_policies << iam_policy.policy_name if (admin_policies.present? && admin_policies.all?)
        end
      else
        admin_policies = check_administrative_privileges_for_policy(policy_statements)
        master_manger_policies = check_master_manager_policy_role(policy_statements)
        arr_iam_policies << iam_policy.policy_name if (admin_policies.present? && admin_policies.all?)
      end
    end
    return arr_iam_policies.uniq, master_manger_policies.any?
  end

  def check_administrative_privileges_for_policy(policy)
    return if policy.blank?

    arr_policy_details = []
    if policy.try(:[],'Effect').present? &&  policy.try(:[],'Effect').eql?("Allow")
      if policy["Action"].present? && policy["Action"].is_a?(Array)
        status = policy["Action"].any? {|action| action.eql?("*")}
        arr_policy_details << status 
      else
        status = policy["Action"].eql?("*")
        arr_policy_details << status
      end
      if policy["Resource"].present? && policy["Resource"].is_a?(Array)
        status = policy["Resource"].any? {|resource| resource.eql?("*")}
        arr_policy_details << status
      else
        status = policy["Resource"].eql?("*")
        arr_policy_details << status
      end
    end
    arr_policy_details
  end
  
  def check_master_manager_policy_role(policy)
    return if policy.blank?

    arr_iam_policies = []
    if policy.try(:[],'Effect').present? &&  policy.try(:[],'Effect').eql?("Allow") &&  policy.try(:[],'Action').present?
       arr_iam_policies = check_allowed_policies(policy['Action'])
    end
    if policy.try(:[],'Effect').present? &&  policy.try(:[],'Effect').eql?("Deny") &&  policy.try(:[],'Action').present?
       arr_iam_policies += check_denied_policies(policy['Action'])
    end
    arr_iam_policies
  end

  def check_allowed_policies(policy_action)
    return if policy_action.blank?

    allowed_policies = []
    if policy_action.is_a?(Array)
      allowed_policies << SecurityScannerConstants::ALLOWED_MASTER_POLICIES.any? {|policy| policy_action.include?(policy)}
      allowed_policies << SecurityScannerConstants::ALLOWED_MANAGER_POLICIES.any? {|policy| policy_action.include?(policy)}
    else
      allowed_policies << SecurityScannerConstants::ALLOWED_MASTER_POLICIES.include?(policy_action)
      allowed_policies <<  SecurityScannerConstants::ALLOWED_MANAGER_POLICIES.include?(policy_action)
    end
    allowed_policies
  end

  def check_denied_policies(policy_action)
    return if policy_action.blank?

    denied_policies = []
    if policy_action.is_a?(Array)
      denied_policies << SecurityScannerConstants::DENIED_MASTER_POLICIES.any? {|policy| policy_action.include?(policy)}
      denied_policies << SecurityScannerConstants::DENIED_MANAGER_POLICIES.any? {|policy| policy_action.include?(policy)}
    else
      denied_policies << SecurityScannerConstants::DENIED_MASTER_POLICIES.include?(policy_action)
      denied_policies <<  SecurityScannerConstants::DENIED_MANAGER_POLICIES.include?(policy_action)
    end
    denied_policies
  end

  
  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: object.aws_account_id,
        service_name: @adapter.try(:name),
        service_type: "AWSAccount",
        category: category,
        state: 'N/A',
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
    
  end
  