module Azure
  module Compute
    module AvailabilitySetRepresenter
include Roar::JSON
include Roar::Hypermedia
      include AzureServicesRepresenter

      property :update_domain_count
     	property :fault_domain_count
     	property :managed

     	# def virtual_machines
     	# end
    end
  end
end