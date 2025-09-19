# The following worker is no longer in use.
# Keeping it here for reference until the transition is complete.
# Marked as dead code on: 2024-01-30

class AzureAutoAssignRecommendationTaskWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, retry: false, backtrace: true

  DEFAULT_CURRENCY_DETAILS = ['USD', 1]

  def perform(policy_ids)
    CSLogger.info "Creating recommendation tasks for azure"
    policies = RecommendationTaskPolicies::Azure.where(id: policy_ids).select{|p| p.valid_policy? }
    policies.each do |policy|
      begin
        recommendation_params_arr = []
        account = policy.account
        tenant = policy.tenant
        adapter_ids = policy.groups_adapter_ids
        next if adapter_ids.empty?

        policy.recommendation_policy_criterium.each do |policy_criteria|
          policy_criteria.service_type.each do |st|
            if policy_criteria.service_category.eql?("Unused")
              region_ids = policy.account.get_enabled_regions('Azure').pluck(:id)
              filters = { adapter_id: policy.groups_adapter_ids, account: policy.account, region_id: region_ids, tenant_tags: [], idle_instance: true }
              services = if st.eql?("idle_vm")
                  ServiceAdviser::Azure.get_idle_vm(filters)
                elsif st.eql?("idle_stopped_vm")
                  ServiceAdviser::Azure.get_idle_stopped_vm(filters)
                elsif st.eql?("idle_databases")
                  ServiceAdviser::Azure.get_idle_databases(filters)
                elsif st.eql?("idle_disks")
                  ServiceAdviser::Azure.get_idle_disks(filters)
                elsif st.eql?('unassociated_lbs')
                  ServiceAdviser::Azure.get_unassociated_lbs(filters)
                elsif st.eql?('idle_lbs')
                  ServiceAdviser::Azure.get_idle_lbs(filters)
                elsif st.eql?('get_unassociated_public_ips')
                  ServiceAdviser::Azure.get_unassociated_public_ips(filters)
                elsif st.eql?('unattached_disks')
                  ServiceAdviser::Azure.get_unattached_disks(filters)
                elsif st.eql?('unused_snapshots')
                  ServiceAdviser::Azure.get_unused_snapshots(filters)
                elsif st.eql?('idle_elastic_pools')
                  ServiceAdviser::Azure.get_idle_elastic_pools(filters)
                elsif st.eql?('idle_blob')
                  ServiceAdviser::Azure.get_idle_blob_services(filters)
                elsif st.eql?('idle_app_service_plans')
                  ServiceAdviser::Azure.get_idle_app_service_plans(filters)
                elsif st.eql?('unused_app_service_plans')
                  ServiceAdviser::Azure.get_unused_app_service_plans(filters)
                elsif st.eql?("idle_aks")
                  ServiceAdviser::Azure.get_idle_aks(filters)
                end
              next if services.empty?
              services = services.where(adapter_id: adapter_ids)
              services = if policy_criteria.criteria["recommendations_by_high_cost"].present?
                           number_of_services = policy_criteria.criteria["recommendations_by_high_cost"].match(/\d+/).to_s.to_f rescue 0
                           services.order('cost_by_hour DESC').limit(number_of_services)
                         elsif policy_criteria.criteria["resource_mec_greater_than"].present?
                           cost_by_hour_value = (policy_criteria.criteria["resource_mec_greater_than"].to_f)/(24*30) rescue 0
                           services.where("cost_by_hour >= ?", cost_by_hour_value)
                         end
            else
              klass = SaRecommendation::AZURE_UNOPTIMIZED[st]
              filters  = { adapter_id: adapter_ids, from_recommendation_worker: true }
              unoptimsed_services = if st.eql?('vm_right_sizings')
                           vms = Rightsizings::RightSizingService.get_right_sized_vms(filters, account, tenant, DEFAULT_CURRENCY_DETAILS)
                           vms.present? ? Azure::Rightsizing.in(_id: vms.pluck(:id)) : []
                         elsif st.eql?('sqldb_rightsizing')
                           sql_dbs = Rightsizings::RightSizingService.get_right_sized_sqldbs(filters, account, tenant, DEFAULT_CURRENCY_DETAILS)
                           sql_dbs.present? ? Azure::Rightsizing.in(_id: sql_dbs.pluck(:id)) : []
                         elsif st.eql?('hybrid_benefit_vm')
                           ahub_vms = Recommendation::Azure::AhubVmFetcherService.fetch_ahub_vms_recommendation(filters, account, tenant, DEFAULT_CURRENCY_DETAILS)
                           ahub_vms.present? ? Azure::Rightsizing.in(_id: ahub_vms.pluck(:id)) : []
                         elsif st.eql?('hybrid_benefit_sql_db')
                           ahub_sql_dbs = Recommendation::Azure::AhubSQLDBFetcherService.fetch_ahub_sql_db_recommendation(filters, account, tenant, DEFAULT_CURRENCY_DETAILS)
                           ahub_sql_dbs.present? ? Azure::Recommend.in(_id: ahub_sql_dbs.pluck(:id)) : []
                         elsif st.eql?('hybrid_benefit_elastic_pool')
                           ahub_elatic_pools = Recommendation::Azure::AhubSQLElasticPoolFetcherService.fetch_ahub_sql_elastic_pool_recommendation(filters, account, tenant, DEFAULT_CURRENCY_DETAILS)
                           ahub_elatic_pools.present? ? Azure::Recommend.in(_id: ahub_elatic_pools.pluck(:id)) : []
                         end
              next if unoptimsed_services.empty?

              unoptimsed_services = if policy_criteria.criteria["recommendations_by_high_cost"].present?
                                      number_of_services = policy_criteria.criteria["recommendations_by_high_cost"].match(/\d+/).to_s.to_f rescue 0
                                      unoptimsed_services.order("costsavedpermonth DESC").limit(number_of_services)
                                    elsif policy_criteria.criteria["resource_mes_greater_than"].present?
                                      cost_by_hour_value = (policy_criteria.criteria["resource_mec_greater_than"].to_f)/(24*30)  rescue 0
                                      unoptimsed_services.where({"costsavedpermonth" => {'$gte' => cost_by_hour_value}})
                                    end
              #Filter services from policy group adapters and idle instances
              services = Azure::Resource.active.where("provider_data->>'id' IN(?)", unoptimsed_services.pluck(:provider_id)).where(adapter_id: adapter_ids) if unoptimsed_services.present?
            end
            create_recommendation_task_for_azue_services(services, policy_criteria, st, recommendation_params_arr)
          end
        end
        create_sa_recommendation_and_send_mail_to_policy_user(policy, recommendation_params_arr) if recommendation_params_arr.present?
      rescue Exception => error
        CSLogger.error error.backtrace
        next
      ensure
        # updating policy last execution
        policy.update_column(:last_run_at, Date.today)
      end
    end
  end

  def create_recommendation_task_for_azue_services(services, policy_criteria, st, recommendation_params_arr)
    CSLogger.info "=======================#{st}=====#{services&.count}"

    return unless services.present?
    if policy_criteria.service_category.eql?("Unused")
      services.group_by{|s| s.type}.each do |service_class, services|
        create_azure_recommendation_task_params(services,policy_criteria, st, recommendation_params_arr)
      end
    else
      create_azure_recommendation_task_params(services,policy_criteria, st, recommendation_params_arr)
    end
  end

  def create_azure_recommendation_task_params(services,policy_criteria, st, recommendation_params_arr)
    policy = policy_criteria.recommendation_task_policy
    assign_to = policy.assign_to['custom_key_attributes'].present? ? policy.get_assign_to_emails : policy.assign_to
    recommendation_params = {
        "assign_to": assign_to,
        "service_type": st,
        "assigner_comment": policy_criteria.assigner_comment,
        "additional_comment": policy_criteria.additional_comment,
        "category": policy_criteria.service_category,
        "state": "assigned",
        "user_id": policy.user.id,
        "recommendation_task_policy_id": policy.id
      }
      data = []
      services.each do |service|
        data << {
            "adapter_id": service.adapter.id,
            "provider_id": service.try(:azure_resource_url)
          }
    end
    recommendation_params.merge!({"data": data})
    recommendation_params_arr << recommendation_params
  rescue Exception => error
    CSLogger.error error.message
  end

  def create_sa_recommendation_and_send_mail_to_policy_user(policy, recommendation_params_arr)
    sa_recommendation_ids = []
    recommendation_params_arr.each do | recommendation_params |
      SaRecommendationService.create("Azure",recommendation_params, policy.user, policy.account, policy.tenant) do |result|
        result.on_success do |response|
          sa_recommendation_ids << response[:sa_recommendations].pluck(:id)
        end
        result.on_validation_error { |errors| 
        CSLogger.error errors.join(",") 
        }
        result.on_error   { |errors|
        CSLogger.error errors.message
        }
      end
    end
    all_sa_recommendation_ids = sa_recommendation_ids.flatten.compact
    # send email only once per policy
    SaRecommendationNotifierWorker.perform_async({sa_recommendation_ids: all_sa_recommendation_ids , host: policy.account.organisation.host_url , tenant_id: policy.tenant.id, current_user_id: policy.user_id, csv: true}) if all_sa_recommendation_ids.present?
    CSLogger.info "Done for task creation for policy #{policy.name}"
  end

end