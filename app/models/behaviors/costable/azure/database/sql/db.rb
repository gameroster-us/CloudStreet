module Behaviors
  module Costable
    module Azure
      module Database
        module SQL
          module DB
            def meter_rate(rate_data)
              hourly_rate, unit_rate = 0.0, 0.0
              if rate_data["MeterName"] == "Basic Database Days"
                hourly_rate = (rate_data["MeterRates"]["0"])/24
                unit_rate = (rate_data["MeterRates"]["0"])/24
              end
              return hourly_rate, unit_rate
            end
          end
        end
      end
    end
  end
end