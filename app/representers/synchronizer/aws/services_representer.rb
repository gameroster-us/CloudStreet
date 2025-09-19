module Synchronizer
  module AWS
    module ServicesRepresenter
    include Roar::JSON
    include Roar::Hypermedia

      collection(
        :vpc_services,
        class: Service,
        extend: Synchronizer::AWS::ServiceRepresenter
      )

      def vpc_services
        collect
      end
    end
  end
end
