module Recommendation
   module Azure
    class AhubVmFetcherService < ApplicationService
      class << self

        def fetch_ahub_vms_recommendation(params, current_account, current_tenant, current_tenant_currency_rate, &block)
          params[:adapter_id] = ServiceAdviser::Base.fetch_normal_adapter_ids(current_tenant, 'Adapters::Azure', params[:adapter_id])
          params[:region_id] = if params[:region_id].blank?
                                current_account.get_enabled_regions_ids(:azure)
                                else
                                  Array[*params[:region_id]]
                                end
          order_by = params["sort"] || 'DESC'
          active_recommendation_ahub_vms = ::Azure::Rightsizing.get_ahub_vms_recommendation(params)
          running_ahub_vm_size_hash = fetch_filtered_ahub_vms_recommendation(params, current_account, current_tenant, active_recommendation_ahub_vms)
          ahub_vms = active_recommendation_ahub_vms.where(:provider_id.in => running_ahub_vm_size_hash.keys)
                                                   .order_by(costsavedpermonth: "#{order_by}".to_sym)
          return ahub_vms if params[:from_recommendation_worker]

          ahub_vms_with_currency_converted = convert_into_current_tenant_currency(ahub_vms, current_tenant_currency_rate)
          return ahub_vms_with_currency_converted unless block_given?

          response = format_response(ahub_vms_with_currency_converted, params, current_tenant_currency_rate[0])
          status Status, :success, response, &block
        rescue StandardError => e
          status Status, :error, e, &block
        end

        def fetch_filtered_ahub_vms_recommendation(params, current_account, current_tenant, active_recommendation_ahub_vms)
          provider_ids = active_recommendation_ahub_vms.pluck(:provider_id)
          tags = JSON.parse(params["tags"]) rescue []
          tag_operator = params["tag_operator"].present? ? params["tag_operator"] : "OR"
          query = ::Azure::Resource::Compute::VirtualMachine.where(adapter_id: params[:adapter_id], region_id: params[:region_id])
                                                          .active.ahub_eligible_vms
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
          running_vms_and_size = query.pluck("provider_data->>'id'", "data->>'vm_size'").to_h rescue []
        end

        def adapter_wise_ahub_vm_recommendation(current_account, current_tenant, params, current_tenant_currency_rate, &block)
          params[:adapter_id] = 'all'
          adapters = if params[:adapter_name].present?
                      current_tenant.adapters.azure_adapter.normal_adapters.available.name_like(params[:adapter_name])
                     else
                      current_tenant.adapters.azure_adapter.normal_adapters.available
                     end
          params[:adapter_id] = adapters.ids
          recommendation_ahub_vms = fetch_ahub_vms_recommendation(params, current_account, current_tenant, current_tenant_currency_rate) || []
          savings = {}
          counts = {}
          recommendation_ahub_vms.group_by(&:subscription_id).each do |k, v|
            savings.merge!(k => v.pluck(:costsavedpermonth)&.sum)
            counts.merge!(k => v.count)
          end

          results = adapters.map do |a|
            {
              adapter_id: a.id,
              adapter_name: a.name,
              potential_saving: savings[a.subscription_id].to_f,
              no_of_instance: counts[a.subscription_id] || 0
            }
          end
          total_saving = savings.values.sum rescue 0.0
          total_count = counts.values.sum rescue 0
          response = {
            adapters: results || [],
            total_potential_saving: total_saving,
            all_ahub_recommended_instance_count: total_count
          }
          status Status, :success, response, &block
        rescue StandardError => e
          status Status, :error, e, &block
        end

        def recommended_ahb_vms_csv(res, current_organisation)
          adapter_map = current_organisation.adapters.azure_adapter.each_with_object({}) { |adapter, memo| memo[adapter.subscription_id] = adapter.slice(:name) }
          attributes = ['Resource Name',
                        'Subscription Id',
                        'Subscription Name',
                        'Region',
                        'Resource Group',
                        'VM Size',
                        'Image Type',
                        'Tags',
                        'MEC',
                        'AHUB MEC',
                        'MES',
                        'Task Status'
                       ]
          csv_records = res.map { |i| [i.name, i.subscription_id, adapter_map[i.subscription_id]['name'] || 'N/A', i.region_name, i.resource_group, i.instancetype,
            i.additional_properties['image_type'], i.instancetags, (i.try(:priceperunit).to_f * 24 * 30).try(:round, 2), (i.try(:ahub_priceperunit).to_f * 24 * 30).try(:round, 2), i.costsavedpermonth.round(2),
            SaRecommendation.find_by(provider_id: i.provider_id)&.state&.capitalize || 'N/A' ] }
          csv = CSV.generate(headers: true) do |csv|
            csv << attributes
            csv_records.each do |rec|
              csv << rec
            end
          end
          csv
        end

        def format_response(ahub_vms, params, current_tenant_currency_code)
          vm_count = ahub_vms.count
          total_saving = ahub_vms.pluck('costsavedpermonth')&.sum.round(2)
          meta = { meta_data: { total_saving: total_saving, vm_count: vm_count, currency: current_tenant_currency_code } }
          ahub_vms = ahub_vms.paginate(page: params[:page], per_page: params[:limit]) if ahub_vms.present? && params[:page].present? && params[:limit].present?
          # right_sized_vms = add_comment_count(right_sized_vms, params, 'Azure') Not Added the functionaity yet
          [ahub_vms, meta]
        end

        def convert_into_current_tenant_currency(ahub_vms, current_tenant_currency_rate)
          ahub_vms.map do |ahub_vm|
            ahub_vm.priceperunit = ahub_vm.priceperunit * current_tenant_currency_rate[1]
            ahub_vm.ahub_priceperunit = ahub_vm.ahub_priceperunit * current_tenant_currency_rate[1]
            ahub_vm.costsavedpermonth = ahub_vm.costsavedpermonth * current_tenant_currency_rate[1]
            ahub_vm
          end
        end
      end
    end
  end
end
