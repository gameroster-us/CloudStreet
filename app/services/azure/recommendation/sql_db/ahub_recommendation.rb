# Azure::Recommendation::SqlDb::AhubRecommendation.new(adapter_id: '')

module Azure
  module Recommendation
    module SQLDB
      class AhubRecommendation
        include Azure::Recommendation::SQLDB::AhubLicenseInfoFetcher
        include ::Recommendation::Azure::TableUpdater

        attr_accessor :adapter, :account, :subscription_id
        def initialize(**options)
          @adapter = Adapter.find_by_id(options[:adapter_id])
          @account = @adapter.account
          @subscription_id = @adapter.subscription_id
        end

        def start_recommendation_process
          set_require_data
          recommendations_arr = []
          ahub_eligible_sql_dbs.each do |sql_db|
            begin
              @license_cost = 0.0
              @sql_db_instance = sql_db
              recommendations_arr << recommendation_result
            rescue StandardError => e
              CSLogger.error "===== SqlDb::AhubRecommendation : something went wrong--- Error : #{e.message} ====="
            end
          end
          update_recommendation_table(recommendations_arr, 'ahub_sql_db')
        end

        def ahub_eligible_sql_dbs
          Azure::Resource::Database::SQL::DB.where(adapter_id: @adapter.id)
                                            .active
                                            .ahub_eligible_sql_dbs
        end

        private

        def recommendation_result
          CSLogger.info "Azure AHUB Recommendation process started for organisation : #{adapter.account.organisation.subdomain} --- SQL DB : #{@sql_db_instance.name}"
          set_license_cost!
          return unless @license_cost.positive?

          recommendation_hash
        end

        def recommendation_hash
          ahub_priceperunit = (@sql_db_instance.cost_by_hour - @license_cost).to_f
          cost_save_per_month = (@license_cost * 24 * 30).to_f
          tag_string = ''
          tag_string += @sql_db_instance.tags.map { |tag| "#{tag['key']}:#{tag['value']}" }.join(' | ').tr('#;', '') if @sql_db_instance.tags.present?
          {
            provider_id: @sql_db_instance.provider_data['id'],
            name: @sql_db_instance.name,
            account_id: adapter.account_id,
            subscription_id: adapter.subscription_id,
            region_id: @sql_db_instance.region_id,
            resource_group: @sql_db_instance.resource_group_name,
            priceperunit: @sql_db_instance.cost_by_hour.to_f,
            ahub_priceperunit: ahub_priceperunit,
            costsavedpermonth: cost_save_per_month,
            instancetags: tag_string,
            region_name: @sql_db_instance.region_name,
            region: @sql_db_instance.region_code,
            instancetype: @sql_db_instance.current_service_objective_name,
            additional_properties: {},
            resource_type: 'ahub_sql_db'
          }
        end
      end
    end
  end
end