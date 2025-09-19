class FetchRISpPotentialBenefitAccountWiseWorker
  include Sidekiq::Worker
  sidekiq_options queue: :service_adviser_summary, retry: false, backtrace: true

  def perform(billing_adapter_ids)
    adapter = Adapter.find_by(id: billing_adapter_ids)

    return unless adapter&.verify_connections?
    CSLogger.info "---- dumping ri sp data for this account #{adapter.try(:name)} ----"

    aws_ri_hsh = {}
    aws_sp_hsh = {}
    # Getting RI data Based on Billing Adapter
    RISpRecommendation::RI_SERVICES.keys.each do |service_type|
      RISpRecommendation.get_ri_recommedations(adapter, service_type) do |response|
        response.on_success { |result| aws_ri_hsh.merge!(result) { |_,o,n| o+n } }
      end
    end

    # Getting SP data Based on Billing Adapter
    RISpRecommendation::SAVINGS_PLAN_SERVICES.keys.each do |service_type|
      RISpRecommendation.get_saving_plan_recommendations(adapter, service_type) do |response|
        response.on_success { |result| aws_sp_hsh.merge!(result) { |_,o,n| o+n } }
      end
    end

    save_recommendations(billing_adapter_ids, 'RiRecommendation', aws_ri_hsh) if aws_ri_hsh.present?
    save_recommendations(billing_adapter_ids, 'SpRecommendation', aws_sp_hsh) if aws_sp_hsh.present?
  rescue Exception => e
    CSLogger.info "!!!!! Unable to dump ri sp cost for this billing adapter: #{adapter.try(:name)}"
    CSLogger.info "Message | #{e.message}"
    CSLogger.info "Bactrace | #{e.backtrace}"
  end

  def save_recommendations(billing_adapter_ids, type, recommendations)
    AWSRecommendation.where(billing_adapter_id: billing_adapter_ids, type: type).destroy_all
    billing_adapter_ids.each do |adapter_id|
       recommendations.each_pair do |account_id, value|
          AWSRecommendation.create(billing_adapter_id: adapter_id, type: type, aws_account_id: account_id, potential_benifit: value)
       end
    end
  end
end