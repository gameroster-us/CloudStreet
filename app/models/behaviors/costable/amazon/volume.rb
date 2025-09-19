module Behaviors
  module Costable
    module Amazon
      module Volume
        def compute_hourly_cost(template_costs)
          volume_types = {
                          'general purpose ssd (gp2)'   =>  'ebsGPSSD',
                          'general purpose ssd (gp3)'   =>  'ebsGPSSD3',
                          'general purpose (ssd)'       =>  'ebsGPSSD',
                          'gp2'                         =>  'ebsGPSSD',
                          'provisioned iops (ssd)'      =>  'ebsPIOPSSSD',
                          'provisioned iops ssd (io1)'  =>  'ebsPIOPSSSD',
                          'provisioned iops ssd (io2)'  =>  'ebsPIOPSSSD2',
                          'io1'                         =>  'ebsPIOPSSSD',
                          'magnetic'                    =>  'Amazon EBS Magnetic volumes',
                          'standard'                    =>  'Amazon EBS Magnetic volumes',
                          'sc1'                         =>  'ebsColdHDD',
                          'cold hdd'                    =>  'ebsColdHDD',
                          'st1'                         =>  'ebsTOHDD',
                          'throughput optimized hdd'    =>  'ebsTOHDD'
                        }
          month_specifications = { "days" => 30, "hours" => 30*24, "million_seconds" => 2.6352 }
          volume_type = self.volume_type.downcase unless self.volume_type.nil?

          volume_costs = template_costs["ec2_ebs"].detect{|vol| volume_types[volume_type].eql?(vol["name"])} rescue nil
          if volume_type && volume_costs
            case volume_type
            when 'general purpose (ssd)', 'gp2', 'general purpose ssd (gp2)', 'general purpose ssd (gp3)', 'sc1', 'cold hdd', 'st1', 'throughput optimized hdd'
              rate_per_gb = volume_costs['values'].detect{|val| val['rate'] == "perGBmoProvStorage"}
              volume_cost_per_month = self.size.to_f * rate_per_gb["prices"]["USD"].to_f
              volume_cost_per_hour = volume_cost_per_month/month_specifications['hours']
            when "provisioned iops (ssd)", 'io1', 'provisioned iops ssd (io1)', 'provisioned iops ssd (io2)'
              rate_per_gb = volume_costs['values'].detect{|val| val['rate'] == "perGBmoProvStorage"}
              rate_per_iops = volume_costs['values'].detect{|val| val['rate'] == "perPIOPSreq"}
              volume_cost_per_gb = self.size.to_f * rate_per_gb["prices"]["USD"].to_f
              volume_cost_per_iops = self.iops.to_f * rate_per_iops["prices"]["USD"].to_f
              volume_cost_per_month = volume_cost_per_gb + volume_cost_per_iops
              volume_cost_per_hour = volume_cost_per_month/month_specifications['hours']
            when "magnetic", 'standard'
              rate_per_gb = volume_costs['values'].detect{|val| val['rate'] == "perGBmoProvStorage"}
              # rate_per_mmio = volume_costs['values'].detect{|val| val['rate'] == "perMMIOreq"} rescue 0
              volume_cost_per_gb = self.size.to_f * rate_per_gb["prices"]["USD"].to_f
              #volume_cost_per_mmio = self.iops.to_f * month_specifications['million_seconds'] * rate_per_mmio["prices"]["USD"].to_f rescue 0
              # volume_cost_per_month = volume_cost_per_gb + volume_cost_per_mmio
              #No need to add iops cost in magnetic volume
              volume_cost_per_month = volume_cost_per_gb
              volume_cost_per_hour = volume_cost_per_month/month_specifications['hours']
            else
              #Do nothing
            end
          end
          volume_cost_per_hour.nil? ? 0 : volume_cost_per_hour
        rescue Exception => e
          # CSLogger.error("error in cost cacl #{e.class} #{e.message} #{e.backtrace}")
          0.0
        end
      end
    end
  end
end
