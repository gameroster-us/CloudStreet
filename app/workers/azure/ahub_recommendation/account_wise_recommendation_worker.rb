# frozen_string_literal: false

module Azure
  module AhubRecommendation
    # Worker to run account wise VM Azure Hybrid Benefit Recommendation
    class AccountWiseRecommendationWorker
      include Sidekiq::Worker
      sidekiq_options queue: :azure_recommendation, backtrace: true

      def perform(options)
        service_klass = case options['type']
                        when 'sql_db'
                          ::Azure::Recommendation::SQLDB::AhubRecommendation
                        when 'elastic_pool'
                          ::Azure::Recommendation::SQLElasticPool::AhubRecommendation
                        else
                          ::Azure::Recommendation::AhubRecommendation
                        end
        options['adapter_ids'].each do |adapter_id|
          service_klass.new(adapter_id: adapter_id).start_recommendation_process
        end
      end
    end
  end
end
