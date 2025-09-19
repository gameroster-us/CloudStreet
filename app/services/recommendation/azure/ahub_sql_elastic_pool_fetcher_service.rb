module Recommendation
   module Azure
    class AhubSQLElasticPoolFetcherService < ApplicationService
      class << self

        def fetch_ahub_sql_elastic_pool_recommendation(params, current_account, current_tenant, current_tenant_currency_rate, &block)
          params[:adapter_id] = ServiceAdviser::Base.fetch_normal_adapter_ids(current_tenant, 'Adapters::Azure', params[:adapter_id])
          params[:region_id] = if params[:region_id].blank?
                                current_account.get_enabled_regions_ids(:azure)
                                else
                                  Array[*params[:region_id]]
                                end
          order_by = params["sort"] || 'DESC'
          ahub_recommendation_elastic_pools = ::Azure::Recommend.get_ahub_sql_elastic_pool_recommendation(params)
          elastic_pool_provider_ids = fetch_filtered_ahub_elastic_pool_recommendation(params, current_account, current_tenant, ahub_recommendation_elastic_pools)
          ahub_sql_elastic_pools = ahub_recommendation_elastic_pools.where(:provider_id.in => elastic_pool_provider_ids)
                                                                    .order_by(costsavedpermonth: "#{order_by}".to_sym)
          return ahub_sql_elastic_pools if params[:from_recommendation_worker]

          ahub_sql_elastic_pools_with_currency_converted = convert_into_current_tenant_currency(ahub_sql_elastic_pools, current_tenant_currency_rate)
          return ahub_sql_elastic_pools_with_currency_converted unless block_given?

          response = format_response(ahub_sql_elastic_pools_with_currency_converted, params, current_tenant_currency_rate[0])
          status Status, :success, response, &block
        rescue StandardError => e
          status Status, :error, e, &block
        end

        def fetch_filtered_ahub_elastic_pool_recommendation(params, current_account, current_tenant, ahub_recommendation_elastic_pools)
          provider_ids = ahub_recommendation_elastic_pools.pluck(:provider_id)
          tags = JSON.parse(params["tags"]) rescue []
          tag_operator = params["tag_operator"].present? ? params["tag_operator"] : "OR"
          query = ::Azure::Resource::Database::SQL::ElasticPool.where(adapter_id: params[:adapter_id], region_id: params[:region_id])
                                                          .active
                                                          .ahub_eligible_elastic_pool
                                                          .exclude_aks_resource_group_services
                                                          .exclude_databricks_resource_group_services
                                                          .where("provider_data->>'id' IN(?)", provider_ids)
          unless params[:azure_resource_group_id].present?
            query = query.filter_resource_group(current_tenant.azure_resource_group_ids)
          else
            query = query.where(azure_resource_group_id: params[:azure_resource_group_id])
          end
          unless current_tenant.tags.blank?
            filter_tags = [current_tenant.tags]
            query = query.find_with_tags(filter_tags, tag_operator, current_account)
          end
          query = query.find_with_tags(tags, tag_operator, current_account) if tags.present?
          query.pluck("provider_data->>'id'")
        end

        def adapter_wise_ahub_elastic_pool_recommendation(current_account, current_tenant, params, current_tenant_currency_rate, &block)
          params[:adapter_id] = 'all'
          adapters = if params[:adapter_name].present?
                      current_tenant.adapters.azure_adapter.normal_adapters.available.name_like(params[:adapter_name])
                     else
                      current_tenant.adapters.azure_adapter.normal_adapters.available
                     end
          params[:adapter_id] = adapters.ids
          ahub_recommendation_elastic_pools = fetch_ahub_sql_elastic_pool_recommendation(params, current_account, current_tenant, current_tenant_currency_rate) || []
          savings = {}
          counts = {}
          ahub_recommendation_elastic_pools.group_by(&:subscription_id).each do |k, v|
            savings.merge!(k => v.pluck(:costsavedpermonth)&.sum)
            counts.merge!(k => v.count)
          end

          results = adapters.map do |a|
            {
              adapter_id: a.id,
              adapter_name: a.name,
              potential_saving: savings[a.subscription_id].to_f,
              no_of_sql_elastic_pool: counts[a.subscription_id] || 0
            }
          end
          total_saving = savings.values.sum rescue 0.0
          total_count = counts.values.sum rescue 0
          response = {
            adapters: results || [],
            total_potential_saving: total_saving,
            all_ahub_recommended_sql_elastic_pool_count: total_count
          }
          status Status, :success, response, &block
        rescue StandardError => e
          status Status, :error, e, &block
        end

        def recommended_ahub_elastic_pool_csv(results, current_organisation)
          adapter_map = current_organisation.adapters.azure_adapter.each_with_object({}) { |adapter, memo| memo[adapter.subscription_id] = adapter.slice(:name) }
          attributes = ['Resource Name',
                        'Subscription Id',
                        'Subscription Name',
                        'Region',
                        'Resource Group',
                        'Elastic Pool Size',
                        'Tags',
                        'MEC',
                        'AHUB MEC',
                        'MES',
                        'Task Status'
                       ]
          csv_records = map_result_for_csv(results, adapter_map)
          csv = CSV.generate(headers: true) do |csv|
            csv << attributes
            csv_records.each do |rec|
              csv << rec
            end
          end
          csv
        end

        def map_result_for_csv(results, adapter_map)
          results.map do |result|
            [
              result.name, result.subscription_id, adapter_map[result.subscription_id]['name'] || 'N/A',
              result.region_name, result.resource_group,
              result.instancetype, result.instancetags,
              (result.try(:priceperunit).to_f * 24 * 30).try(:round, 2),
              (result.try(:ahub_priceperunit).to_f * 24 * 30).try(:round, 2),
              result.costsavedpermonth.round(2),
              SaRecommendation.find_by(provider_id: result.provider_id)&.state&.capitalize || 'N/A'
            ]
          end
        end

        def format_response(ahub_sql_elastic_pool, params, current_tenant_currency_code)
          sql_elastic_pool_count = ahub_sql_elastic_pool.size
          total_saving = ahub_sql_elastic_pool.pluck('costsavedpermonth')&.sum.round(2)
          meta = { meta_data: { total_saving: total_saving, ahub_sql_elastic_pool_count: sql_elastic_pool_count, currency: current_tenant_currency_code } }
          is_pagination_present = ahub_sql_elastic_pool.present? && params[:page].present? && params[:limit].present?
          ahub_sql_elastic_pool = ahub_sql_elastic_pool.paginate(page: params[:page], per_page: params[:limit]) if is_pagination_present
          [ahub_sql_elastic_pool, meta]
        end

        def convert_into_current_tenant_currency(ahub_sql_elastic_pools, current_tenant_currency_rate)
          ahub_sql_elastic_pools.map do |ahub_sql_elastic_pool|
            ahub_sql_elastic_pool.priceperunit = ahub_sql_elastic_pool.priceperunit * current_tenant_currency_rate[1]
            ahub_sql_elastic_pool.ahub_priceperunit = ahub_sql_elastic_pool.ahub_priceperunit * current_tenant_currency_rate[1]
            ahub_sql_elastic_pool.costsavedpermonth = ahub_sql_elastic_pool.costsavedpermonth * current_tenant_currency_rate[1]
            ahub_sql_elastic_pool
          end
        end
      end
    end
  end
end
