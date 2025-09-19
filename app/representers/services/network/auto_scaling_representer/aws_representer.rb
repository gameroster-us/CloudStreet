module Services
  module Network
    module AutoScalingRepresenter
      module AWSRepresenter
include Roar::JSON
include Roar::Hypermedia
        include ServicesRepresenter
        include AutoScalingRepresenter

        property :launch_configuration_name
        property :availability_zones
        property :subnets
        property :default_cooldown
        property :policies, as: :scaling_policies

        # details
        nested :details do
          property :load_balancers
          property :max_size
          property :min_size
          property :desired_capacity
          property :health_check_type
          property :health_check_grace_period
          property :termination_policies
          property :instances
        end

        property :list_attributes
        property :activity, as: :status
        property :tags
        property :service_tags
        property :service_state, as: :state, exec_context: :decorator

        def list_attributes
          %w(name launch_configuration_name subnets availability_zones default_cooldown)
        end

        def service_state
          return unless environment.present?
          env_state = environment.state
          if env_state == "running"
            represented.state == "environment" ? "starting" : represented.state
          else
            represented.state
          end
        end

        def load_balancers
          fetch_remote_services(Protocols::LoadBalancer).map(&:name)
        end

        def launch_configuration_name
          fetch_first_remote_service(Protocols::AutoScalingConfiguration).try :name
        end

        def availability_zones
          get_az_via_subnet
        end

        def subnets
          parent_subnets_providers.map(&:provider_id)
          # fetch_remote_services(Protocols::Subnet).map(&:provider_id)
        end

        def instances
          data && data['instance_ids']
        end
      end
    end
  end
end
