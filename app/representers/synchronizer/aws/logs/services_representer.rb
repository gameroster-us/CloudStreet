module Synchronizer
  module AWS
    module Logs
      module ServicesRepresenter
include Roar::JSON
include Roar::Hypermedia

        collection(
          :vpc_services,
          class: ServiceSynchronizationHistory,
          extend: Synchronizer::AWS::Logs::ServiceRepresenter
        )

        def vpc_services
          collect
        end
      end
    end
  end
end
