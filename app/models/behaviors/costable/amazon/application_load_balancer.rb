module Behaviors
  module Costable
    module Amazon
      module ApplicationLoadBalancer
        def compute_hourly_cost(template_costs)
          template_costs["ec2_app_elb"]["perELBHour"] || 0.0
        rescue Exception => e
          # CSLogger.error("error in cost cacl #{e.class} #{e.message} #{e.backtrace}")
          0.0
        end
      end
    end
  end
end
