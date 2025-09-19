class TemplateCostService < CloudStreetService
  def self.search(account, params={}, &block)
    if params[:region_id]
      begin
        account = fetch Account, account
        region = fetch Region, params[:region_id]
        account_region = account.get_region(region.id)
        filtered_costings = account_region.get_aws_template_costs
        status Status, :success, filtered_costings, &block
        filtered_costings
      rescue Exception => e
        CSLogger.error("========= error message : #{e.message}")
        CSLogger.error("========= error backtrace : #{e.backtrace}")
        filtered_costings = TemplateCost.dummy_object
        status Status, :success, filtered_costings, &block
        # status Status, :error, I18n.t('errors.template_costs.params_error'), &block
      end
    else
      status Status, :error, I18n.t('errors.template_costs.specify_region'), &block
    end
  end

  def self.fetch_costing_by_region(region, &block)
    begin
      filtered_costings = region.get_aws_template_costs
      status Status, :success, filtered_costings, &block
      filtered_costings
    rescue Exception => e
      CSLogger.error("========= error message : #{e.message}")
      CSLogger.error("========= error backtrace : #{e.backtrace}")
      status Status, :error, I18n.t('errors.template_costs.params_error'), &block
    end
  end
end
