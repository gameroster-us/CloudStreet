module Behaviors
	module AttachDetach
		module AWS
			module Volume

				def mark_as_detached
					self.provider_data["server_id"] = self.server_id = self.server_name = nil
					self.provider_data["state"] = self.status = "available"
					self.provider_data.delete("device")
					self.provider_data.delete("attached_at")
					self.vpc_id = nil
					self.interfaces.delete_all
				end

			end
		end
	end
end