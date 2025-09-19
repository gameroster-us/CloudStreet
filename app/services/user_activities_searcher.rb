class UserActivitiesSearcher < CloudStreetService
  def self.list(account, organisation, tenant, page_params, &block)
    if page_params[:from_date].present? && page_params[:to_date].present? && check_for_today_date(page_params)
      activities = UserActivity.where(created_at: (page_params[:from_date].to_date.beginning_of_day..page_params[:to_date].to_date.end_of_day), account_id: account.id).order('created_at desc')
      total_records = activities.count rescue 0
    else
      all_tenant_ids = if tenant.is_default
        organisation.tenants.pluck(:id)
      else
        [tenant.id]
      end
      controller = page_params[:module_name]
      controller.slice!("-integration") if ["slack-integration", "teams-controller"].include? controller  # Integration module maps to slack controller
      controller.slice!('aws_') if ['aws_budgets'].include? controller
      ip_address = page_params[:ip_address]&.squish

      filter = [
        { "tenant_id" => {"$in" => all_tenant_ids } }
      ]

      
      filter << { "data.username"=> {"$regex"=> /#{page_params[:username]}/i }} if page_params[:username].present?
      filter << { "created_at"=> { "$gte"=> page_params[:from_date].to_date }} if page_params[:from_date].present?
      filter << { "created_at"=> {"$lte"=> page_params[:to_date].to_date }} if page_params[:to_date].present?
      filter << { "controller"=> {"$eq"=> controller }} if page_params[:module_name].present?
      filter << { "ip_address"=> {"$regex"=> /^#{ip_address}/i }} if page_params[:ip_address].present?
      filter << { "data.name"=> {"$regex"=> /#{page_params[:job_name]}/i }} if page_params[:job_name].present?
      filter << { "data.name"=> {"$regex"=> /#{page_params[:search_key]}/i }} if page_params[:search_key].present?
      filter << { "progress.percentage" => { '$gte' => page_params[:min].to_i, '$lte' => page_params[:max].to_i }} if (page_params[:min].present? && page_params[:max].present?)

      result = UserActivity.collection.aggregate([
        { "$match": {"$and": filter} },
        "$facet": {
          "paginatedResult": [
            { "$sort": { "created_at": -1 } },
            { "$skip": ((page_params[:page_number].present? ? page_params[:page_number].to_i : 1) -  1) * page_params[:page_size].to_i },
            { "$limit": page_params[:page_size].to_i }
          ],
          "totalCount": [
            { "$count": 'count' }
          ]
        }
      ]).as_json
      activities =result[0]['paginatedResult'] rescue []
      activities = UserActivity.where(:id.in => activities.map{|a| a["_id"]["$oid"]}).order("created_at desc")

      total_records = result[0]['totalCount'][0]['count'] rescue 0
    end
    status Status, :success, [activities, total_records], &block
    return activities
  end

  def self.check_for_today_date(page_params)
    page_params[:from_date]&.to_date == Date.today && page_params[:to_date]&.to_date == Date.today
  end

  def self.task_log_list(account,params,user ,&block)
    task = fetch Task, params[:task_id] 
    user_activity_log = UserActivityLog.by_account_id(account.id).by_action_owner_id(params[:task_id])
    user_activity_log = user_activity_log.where(:created_at.gte => task.last_execuation_time || task.opt_out_last_updated).order('created_at DESC')
    multiple_execution = user_activity_log.group_by(&:user_activity_id).count
    if multiple_execution > 0 # If user click on run now option before 1 min of event execution
      if task.opt_out_last_updated.present? && task.updated_at > task.opt_out_last_updated
        # Fetching task execution logs and rejecting opt out logs when task is updated
        user_activity_log = user_activity_log.not.in(:action_name => 'opt_out_execution').group_by(&:user_activity_id).first[1]
      else
        user_activity_log = user_activity_log.group_by(&:user_activity_id).first[1]
      end
    end
    user_activity_log = set_user_time_zone(user_activity_log,user)
    status Status, :success, user_activity_log, &block if block_given?
    return user_activity_log
  end

  def self.module_list(account, tenant, &blocks)
    # Slack controller is mapped with Integration Module
    module_list = UserActivity.where(account_id: account.id, tenant_id: tenant.id).pluck(:controller).uniq
    module_list = modify_module_names(module_list)
    status Status, :success, module_list, &blocks
    return module_list
  end

  def self.user_activity_list(account,params,user,&block)
    user_activity_log = UserActivityLog.by_account_id(account.id).by_user_activity_id(params[:id]).order('created_at DESC')
    user_activity_log = set_user_time_zone(user_activity_log,user)
    status Status, :success, user_activity_log, &block
    return user_activity_log
  end

  def self.set_user_time_zone(user_activity_log,user)
    time_zone = user.time_zone.values.uniq.join('/')
    user_activity_log = user_activity_log.inject([]) do |memo,activity|
      activity.display_time_zone = time_zone
      memo << activity
    end
    return user_activity_log
  end

  def self.create_sync_user_activity(user_id, adapter_ids, action, status)
    user = User.find(user_id)
    adapters = Adapter.where(id: adapter_ids)
    if adapters
      adapters.each do |adapter|
        options = {
            controller: "synchronizations",
            action_name: action,
            status: status,
            user: user,
            name: adapter.name,
            current_tenant_id: user.try(:current_tenant)
        }
        @activity = UserActivity.init_activity(options)
        @activity.save
      end
    end
  end

  def self.modify_module_names(module_list)
    module_list.map do |module_name|
      if ["slack", "teams"].include?(module_name)
        module_name << "-integration"
      elsif module_name == 'budgets'
        'aws_budgets'
      else
        module_name
      end
    end
  end

end
