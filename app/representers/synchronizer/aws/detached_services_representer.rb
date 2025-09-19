module Synchronizer
  module AWS
    module DetachedServicesRepresenter
include Roar::JSON
include Roar::Hypermedia

			property :estimated_cost_for_region
			property :service_types

			collection(
				:service_types,
				extend: ::Synchronizer::AWS::DetachedServiceTypesRepresenter
				)

			collection(
				:assignable_environments,
				class: Environment,
				extend: ::Synchronizer::AWS::AssignableEnvironmentsRepresenter
				)

			def service_types
				self[:list_services]
			end
			
			def estimated_cost_for_region
				0.0
			end

			def assignable_environments
				self[:assignable_environments]
			end
		end
  end
end
