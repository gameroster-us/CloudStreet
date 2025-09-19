module Behaviors
  module Costable
    module Azure
      module Network
        module PublicIPAddress
          def meter_rate(rate_data)
            hourly_rate, unit_rate = 0.0, 0.0
            if rate_data["MeterName"] == "IP Address Hours"
              hourly_rate = rate_data["MeterRates"]["0"]
              unit_rate = rate_data["MeterRates"]["0"]
            end
            return hourly_rate, unit_rate
          end
        end
      end
    end
  end
end