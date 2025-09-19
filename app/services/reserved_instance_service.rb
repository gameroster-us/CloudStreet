class ReservedInstanceService < CloudStreetService
  class << self
    def fetch_and_store_r_instances(adapter)
      account = adapter.account
      return unless account
      account_regions = account.account_regions
      account_regions.each do |account_region|
        allowed_regions = %w(af-south-1 ap-east-1 eu-south-1 eu-west-3 eu-north-1 me-south-1 ap-south-1 us-west-1 sa-east-1 us-west-2 ap-northeast-1 ap-northeast-2 ap-northeast-2 ap-southeast-1 ap-southeast-2 eu-central-1 eu-west-1 us-east-1 us-gov-east-1 us-gov-west-1)
        region_code = account_region.region.code
        next if adapter.not_supported_regions.include?(region_code)
        next unless allowed_regions.include?(region_code)
        reserved_instance_sets = get_reserved_instances(adapter, region_code)
        reserved_instance_sets.each do |instance_set|
          next unless instance_set['reservedInstancesId']
          r_attributes = {
            region_id: account_region.region_id,
            adapter_id: adapter.id,
            availability_zone: instance_set['availabilityZone'],
            duration: instance_set['duration'],
            fixed_price: instance_set['fixedPrice'],
            instance_type: instance_set['instanceType'],
            instance_count: instance_set['instanceCount'],
            product_description: instance_set['productDescription'],
            reserved_instances_id: instance_set['reservedInstancesId'],
            start_time: instance_set['start'],
            state: instance_set['state'],
            usage_price: instance_set['usagePrice'],
            end_time: instance_set['end'],
            data: get_data(instance_set),
            provider_data: ProviderWrappers::AWS.parse_remote_service(instance_set)
          }
          account.reserved_instances.build(r_attributes)
          account.save!
        end
      end
    end

    def get_data(instance_set)
      {  
        :tenancy => instance_set['instanceTenancy'],
        :offering_type => instance_set['offeringType'],
        :amount => instance_set['amount']
      }
    end

    def get_reserved_instances(adapter, region_code)
      connection = adapter.connection(region_code, 'AWS')
      remote_obj = connection.describe_reserved_instances
      remote_obj.data[:body]['reservedInstancesSet']
    end
  end 

end
