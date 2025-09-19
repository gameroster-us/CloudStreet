module Behaviors
	module Terminator
		module AWS

			def self.included(receiver)
				receiver.include "Behaviors::Terminator::AWS::#{receiver.to_s.split("::")[-2]}".constantize
			end
			
		end
	end
end