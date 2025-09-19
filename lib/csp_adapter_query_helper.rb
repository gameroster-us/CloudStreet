# This module contains method to apply default filters
module CspAdapterQueryHelper

  def additional_filters_for_csp(filter_parmas, adapter)
    dup_filter_parms = filter_parmas.dup
    dup_filter_parms.push("cost_type != 'Azure Plan (Partner Center)'")
    unless adapter.include_office_cost.eql?('true')
      exluded_services = adapter.excluded_office365_services.pluck(:service_name).compact.uniq
      if exluded_services.include?('Legacy Office Services')
        dup_filter_parms.push("billing_provider != 'office'")
        exluded_services.delete('Legacy Office Services')
      end
      dup_filter_parms.push("NOT regexp_like(service_name, '(#{exluded_services.join('|')})')") if exluded_services.present?
    end
    dup_filter_parms
  end

  def additional_filters_for_csp_in_string(adapter)
    return '' unless adapter.azure_account_type.eql?('csp')

    default_query_string = "AND cost_type != 'Azure Plan (Partner Center)'"
    return default_query_string if adapter.include_office_cost.eql?('true')

    exluded_services = adapter.excluded_office365_services.pluck(:service_name).compact.uniq
    return default_query_string unless exluded_services.present?

    if exluded_services.include?('Legacy Office Services')
      exluded_services.delete('Legacy Office Services')
      "#{default_query_string} AND billing_provider != 'office' AND NOT regexp_like(service_name, '(#{exluded_services.join('|')})')"
    else
      "#{default_query_string} AND NOT regexp_like(service_name, '(#{exluded_services.join('|')})')"
    end
  end

end
