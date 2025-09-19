module CloudTrail::Events::Tag::AddTags
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "Inside process of AddTags for LoadBalancer"
    exec_tag_events do
      resources = collect_lb_ids.uniq
      app_nw_lb_resources = collect_app_nw_lb_ids.uniq
      filter = {adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account_id}
      unless resources.blank?
        CTLog.info "Inside process of AddTags for Classic LoadBalancer"
        lb_type = "classic_lbs"
        all_remote_tags = get_remote_tags(resources, lb_type)
        unless all_remote_tags.blank?
          services = Service.active_services.where(filter).where(provider_id: all_remote_tags.keys)
          update_services_for_create_delete("lbs", services, all_remote_tags)
        end
      end
      unless app_nw_lb_resources.blank?
        CTLog.info "Inside process of AddTags for Application and Network LoadBalancer"
        lb_type = "nw_app_lbs"
        app_nw_remote_tags = get_remote_tags(app_nw_lb_resources, lb_type)
        unless app_nw_remote_tags.blank?
          services = Service.active_services.where(filter).where(provider_id: app_nw_remote_tags.keys)
          update_services_for_create_delete("lbs", services, app_nw_remote_tags)
         end
      end
    end
  end

  def get_remote_tags(resources, lb_type)
    retries ||= 0
    response = {}
    if lb_type.eql?("classic_lbs")
      lb_agent = ProviderWrappers::AWS::Networks::LoadBalancer.elb_agent(@adapter, @region.code)
      active_lbs = (lb_agent.describe_load_balancers.body["DescribeLoadBalancersResult"]["LoadBalancerDescriptions"] || []).pluck("LoadBalancerName")
      resources.each_slice(100) do |res_batch|
        active_lb_ids = res_batch & active_lbs
        next if active_lb_ids.blank?
        data = begin
                 lb_agent.describe_tags(active_lb_ids).body["DescribeTagsResult"]["LoadBalancers"]
               rescue
                 []
               end
        response.merge!(data.each_with_object({}) { |h, memo| memo[h["LoadBalancerName"]] = h["Tags"] })
      end
      return response
    else
      v2_elb_client = @adapter.connection_v2_elb_client(@region.code)
      active_lbs = (v2_elb_client.describe_load_balancers({}).load_balancers || []).pluck(:load_balancer_arn)
      resources.each_slice(100) do |res_batch|
        active_lb_ids = res_batch & active_lbs
        next if active_lb_ids.blank?
        resp = v2_elb_client.describe_tags(resource_arns: active_lb_ids)
        next if resp.tag_descriptions.blank?
        resp.tag_descriptions.each_with_object({}) do |res, memo|
          next if res.tags.blank?
          memo = res.tags.inject([]) { |h, v| h << { v['key'] => v['value']} }.inject(:merge)
          response.merge!(res.resource_arn.split("/")[-2] => memo)
        end
      end
      return response
    end
  rescue StandardError, Aws::ElasticLoadBalancingV2::Errors, ::Adapters::InvalidAdapterError => e
    if e.message.eql?("AccessDenied")
      CTLog.error "=======#{e.message} Access denied for #{@adapter.name} in #{@region.code}===="
    elsif e.message.eql?("RequestLimitExceeded => Request limit exceeded.") && (retries += 1) < 3
      CTLog.error "Excon Exeption:: => #{e.message}.Retrying ." if retries.eql?(0)
      sleep 5
      retry
    elsif e.message.eql?("UnauthorizedOperation => You are not authorized to perform this operation.")
      CTLog.error "Error : ====== #{e.message} for #{@adapter.name} in #{@region.code} ===="
      []
    else
      CTLog.error "Error : #{e.message}"
      CTLog.error "BackTrace   : #{e.backtrace}"
    end
    return {}
  end
end
