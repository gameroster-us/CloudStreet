module Synchronizer
	module AWS
		module DetachedServiceTypesRepresenter
include Roar::JSON
include Roar::Hypermedia

			property :service_type
			# property :services

			collection(
				:services,
				extend: ::Synchronizer::AWS::DetachedServiceRepresenter
				)


			def service_type
				self[:service_type]
			end

			def services
				self[:services]
			end
		end
	end
end
