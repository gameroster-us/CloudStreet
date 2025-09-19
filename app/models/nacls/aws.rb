class Nacls::AWS < Nacl
  extend AWSRecord::CommonAttributeMapper

  def save_nacl_from_aws
    agent = ProviderWrappers::AWS::Networks::Nacl.compute_agent(vpc.adapter, region.code)
    remote_nacl =  ProviderWrappers::AWS::Networks::Nacl.get(agent, provider_id)
    Nacl.update_default_nacl(remote_nacl, vpc)
  end

  class << self
    def terminate_via_reload(service)
      self.where(
        adapter_id: service.adapter_id,
        region_id: service.region_id,
        account_id: service.account_id,
        provider_id: service.provider_id
        ).delete_all
    end

    def update_base_table(remote_nacl)
      if remote_nacl.provider_data["default"]
        super(remote_nacl){|service, filters|
          #to be modified after reusable implementation is complete
          self.where(filters.slice!(:provider_id)).where.not(provider_id: filters[:provider_id]).destroy_all
        }
      end
    end

    def format_attributes_by_raw_data(aws_service)
      {
        provider_vpc_id: aws_service.vpc_id,
        entries: aws_service.entries,
        associations: aws_service.associations,
        tags: aws_service.tags,
        name: aws_service.tags["Name"]||aws_service.network_acl_id
      }
    end
  end
end
