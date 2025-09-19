# this class is used for fetching ri & sp recommendations
class RISpRecommendation < CloudStreetService
  AWSSDK = "AWSSdkWrappers::CostExplorer::Client"
  DURATION = 36
  RI_SERVICES = { 'amazon_ec2' => 'Amazon Elastic Compute Cloud - Compute', 'amazon_rds' => 'Amazon Relational Database Service', 'amazon_elastic_cache' => 'Amazon ElastiCache', 'amazon_redshift' => 'Amazon Redshift', 'amazon_elastic' => 'Amazon Elasticsearch Service'}
  DEFAULT_PARAMS = { 'account_scope' => "PAYER", 'term_in_years' => "THREE_YEARS", 'payment_option' => "ALL_UPFRONT", "lookback_period_in_days" => "SEVEN_DAYS" }.with_indifferent_access
  SAVINGS_PLAN_SERVICES = { 'amazon_compute' => 'COMPUTE_SP', 'amazon_ec2' => 'EC2_INSTANCE_SP' }
  DEFAULT_SAVING_PLAN = { 'account_scope' => "PAYER", 'term_in_years' => 'THREE_YEARS', 'payment_option' => "ALL_UPFRONT", "lookback_period_in_days" => "SEVEN_DAYS" }.with_indifferent_access
  class << self
    # This method retrieves reserved instance recommendations for a specific AWS service type of each aws billing adapter for account wise
    def get_ri_recommedations(adapter, service_type, &block)
      ri_purchase_recommendations_list = Hash.new(0)
      begin
        params = DEFAULT_PARAMS.merge!(service: RI_SERVICES[service_type])
        cost_explorer_client = AWSSDK.constantize.new(adapter, 'us-east-1').client
        raw_data = cost_explorer_client.get_reservation_purchase_recommendation(params)
        raw_data.recommendations.each do |recommendation|
      	  recommendation.recommendation_details.each do |recommendation_detail|
            ri_purchase_recommendations_list[recommendation_detail['account_id']] += (recommendation_detail.estimated_monthly_savings_amount.to_f.round(2) * DURATION).round(2)
      	  end
        end
        status Status, :success, ri_purchase_recommendations_list, &block
      rescue Exception => e
        status Status, :error, {}, &block
      end
    end

    # This method retrieves savings plan recommendations for a specific AWS service type of each aws billing adapter for account wise
    def get_saving_plan_recommendations(adapter, service_type,  &block)
      sp_purchase_recommendations_list = Hash.new(0)
      begin
        params = DEFAULT_SAVING_PLAN.merge!(savings_plans_type: SAVINGS_PLAN_SERVICES[service_type])
        cost_explorer_client = AWSSDK.constantize.new(adapter,'us-east-1').client
        raw_data = cost_explorer_client.get_savings_plans_purchase_recommendation(params)
        raw_data.savings_plans_purchase_recommendation.savings_plans_purchase_recommendation_details.each do |recommendation|
          sp_purchase_recommendations_list[recommendation['account_id']] += (recommendation.estimated_monthly_savings_amount.to_f * DURATION).round(2)
        end
        status Status, :success, sp_purchase_recommendations_list, &block
      rescue Exception => e
        status Status, :error, {} , &block
      end
  	end

    # Ri Data fetching from AWSRecommendation table
    def aws_ri_recommedations(adapter, type, &block)
      ri_purchase_recommendations_list = Hash.new(0)
      raw_data = AWSRecommendation.where(billing_adapter_id: adapter.id, type: type)
      raw_data.each do |recommendation|
        ri_purchase_recommendations_list[recommendation['aws_account_id']] += recommendation.potential_benifit.round(2)
      end
      status Status, :success, ri_purchase_recommendations_list, &block
    rescue Exception => e
      status Status, :error, {} , &block
    end

    # Sp Data fetching from AWSRecommendation table
    def aws_saving_plan_recommendations(adapter, type, &block)
      sp_purchase_recommendations_list = Hash.new(0)
      raw_data = AWSRecommendation.where(billing_adapter_id: adapter.id, type: type)
      raw_data.each do |recommendation|
        sp_purchase_recommendations_list[recommendation['aws_account_id']] += recommendation.potential_benifit.round(2)
      end
      status Status, :success, sp_purchase_recommendations_list, &block
    rescue Exception => e
      status Status, :error, {} , &block
    end

    def azure_ri_recommedations(tenant_normal_adapters_ids, &block)
      begin
        azure_ri_recommedations_data = Hash.new(0)
        raw_data = ReservationRecommendations::Azure.where(adapter_id: tenant_normal_adapters_ids, term: 'P3Y', scope: 'Single', look_back_period: 'Last30Days')
        # Pluck only first currency bcuz we assume that currency would be same for all adapters
        currency = raw_data.pluck(:currency).uniq.last 
        raw_data.each do |recommendation|
          azure_ri_recommedations_data[recommendation['subscription_id']] += recommendation.net_savings.round(2)
        end
        hsh = { 'subscription_cost_hsh' => azure_ri_recommedations_data, 'currency' => currency }
       status Status, :success, hsh, &block
     rescue Exception => e
       status Status, :error, {} , &block
     end
  	end
  end
end