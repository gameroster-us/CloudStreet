class ProviderWrappers::AWS::VpcProvider < ProviderWrappers::AWS

  def fetch_remote_vpc(vpc_id)
    agent.vpcs.get(vpc_id) if vpc_id
  end

  def create(create_params)
    CSLogger.info "#{caller[0]}---------create params ---- #{create_params}"
    vpc  = agent.vpcs.create create_params
    vpc.wait_for do
      print "."
      ready?
    end
    vpc.reload
  end

  class << self

    def describe_vpc_attribute(agent, vpc_id, attribute)
     agent.describe_vpc_attribute(vpc_id, attribute).body[attribute]
    end

    def all(agent, filters = {})
      options = {}
      options.merge!({'vpc-id' => filters[:provider_ids]}) if filters[:provider_ids].present?
      agent.vpcs.all(options).reject{|remote_vpc|
        remote_vpc.is_a?(Fog::Compute::AWS::VPC) && remote_vpc.id.blank?
      }
    end

    def get_default_nacl(agent, vpc_id)	  	
      agent.network_acls.all({'vpc-id' => vpc_id, 'default' => 'true'}).first
    end

    def get(agent, vpc_id)
      agent.vpcs.get(vpc_id) if vpc_id
    end
  end
end
