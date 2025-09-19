module V2
  module Environments
	class EnvironmentServices
		attr_accessor :type, :services

		def initialize(service_type,services)
			@type = service_type
			@services = services
		end

	end
  end
end