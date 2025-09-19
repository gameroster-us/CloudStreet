module Services
  module Compute
    module ServerRepresenter
      module VolumesRepresenter
        module AWSRepresenter
include Roar::JSON
include Roar::Hypermedia

          collection(
            :volumes,
            class: Services::Compute::Server::Volume::AWS,
            extend: Services::Compute::ServerRepresenter::VolumeRepresenter::AWSUnsyncedRepresenter
          )

          def volumes
            collect
          end
        end
      end
    end
  end
end
