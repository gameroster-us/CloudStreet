module Behaviors
  module TemplateDeployable
    module Azure
      module Compute
        module VirtualMachine
          module Disk
            def form_template_deployer_hash
              disk = {
                "osType" => self.os_type,
                "name" => self.name,
                "createOption" => self.create_option,
                "vhd" => {
                  "uri" => self.vhd_uri
                },
                "caching" => self.caching
              }
              if self.disk_type == "data_disk"
                disk.merge!({
                  "lun" => self.lun,
                  "diskSizeGB" => disk_size
                })
              end
              disk
            end
          end
        end
      end
    end
  end
end