module Behaviors
  module Costable
    module Amazon
      module EKS
        def compute_hourly_cost(template_costs)
          template_costs["eks"]["perHour"] || 0
        rescue Exception => e
          # CSLogger.error("error in cost cacl #{e.class} #{e.message} #{e.backtrace}")
          0.0
        end
      end
    end
  end
end
