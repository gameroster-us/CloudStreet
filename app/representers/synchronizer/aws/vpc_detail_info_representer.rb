module Synchronizer
  module AWS
    module VpcDetailInfoRepresenter
      include Roar::JSON
      include Roar::Hypermedia

      property :id
      property :name
      property :cidr
      property :tenancy
      property :vpc_id
      property :services, extend: Synchronizer::AWS::ServicesRepresenter
      property :provider, getter: lambda { |args| args[:options][:adapter].provider_name }
      property :available_services
      property :eip_cost,
        getter: lambda { |args|  ((TemplateCosts::AWS.where(region_id: self.region_id).pluck(:data).first.values.first["elastic_ips"]["perAdditionalEIPPerHour"]) rescue 0.0) },
        if: lambda {|args| args[:options][:service_type].eql?("Services::Compute::Server::AWS") }

      def available_services
        if self.synchronized
          rec = Service.where.not(type: Service::LB_SERVICE_TYPES).where(adapter_id: adapter_id, region_id: region_id, account_id: account_id, vpc_id: id).synced_services.select(
            'type AS service_type,SUM("services"."cost_by_hour") AS sum_cost_by_hour'
          ).group(:type).collect do |a|
            sum_cost_by_hour = a.sum_cost_by_hour || 0
            {cost: (sum_cost_by_hour * 24 * 30),service_type: a.service_type}
          end
          lb_types_cost = Service.where(type: Service::LB_SERVICE_TYPES).where(adapter_id: adapter_id, region_id: region_id, account_id: account_id, vpc_id: id).synced_services.collect{ |a| {cost: (a.cost_by_hour * 24 * 30)} }
          unless lb_types_cost.blank?
            rec << {cost: lb_types_cost.sum { |h| h[:cost] }, service_type: "Services::Network::LoadBalancer::AWS" }
          end
          rec
        else
          rec = AWSRecord.where({
            adapter_id: adapter_id,
            region_id: region_id,
            account_id: account_id,
            provider_vpc_id: vpc_id
          }).where.not(
            provider_id: Service.distinct.select("provider_id").joins("INNER JOIN aws_records ON services.provider_id = aws_records.provider_id").where({
              adapter_id: adapter_id,
              region_id: region_id,
              account_id: account_id,
              type: Service::BILLABLE_SERVICES - Service::LB_SERVICE_TYPES
            })).select(
            'type AS service_type,SUM("aws_records"."cost_by_hour") AS sum_cost_by_hour'
          ).group(:type).collect do |a|
              sum_cost_by_hour = a.sum_cost_by_hour || 0
            {cost: (sum_cost_by_hour * 24 * 30),service_type: a.service_type}
          end
          lb_types_cost = AWSRecord.where({
            adapter_id: adapter_id,
            region_id: region_id,
            account_id: account_id,
            provider_vpc_id: vpc_id
          }).where.not(
            provider_id: Service.distinct.select("provider_id").joins("INNER JOIN aws_records ON services.provider_id = aws_records.provider_id").where({
              adapter_id: adapter_id,
              region_id: region_id,
              account_id: account_id,
              type: Service::LB_SERVICE_TYPES
            })).collect{ |a| {cost: (a.cost_by_hour * 24 * 30)} }
          unless lb_types_cost.blank?
            rec << {cost: lb_types_cost.sum { |h| h[:cost] }, service_type: "Services::Network::LoadBalancer::AWS" }
          end
          rec
        end
      end
    end
  end
end
