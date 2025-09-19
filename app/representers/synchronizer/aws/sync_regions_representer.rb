module Synchronizer
  module AWS
    module SyncRegionsRepresenter
      include Roar::JSON
      include Roar::Hypermedia
      property :adapter_id, getter: lambda { |args| args[:options][:adapter].id }
      property :provider, getter: lambda { |args| args[:options][:adapter].provider_name }
      property :auto_sync_to_cs, getter: lambda { |args|
        args[:options][:adapter].get_last_auto_sync_status
      }
      property :scanning_status, getter: lambda { |args|
        args[:options][:adapter].sync_running?
      }
      property :last_run_status, getter: lambda { |args|
        args[:options][:adapter].sync_running? ? Synchronization::RUNNING : args[:options][:adapter].sync_state
      }
      property :started_at, getter: lambda { |args|
        time_zone = args[:options][:current_user].time_zone.map { |_k, v| [v].flatten.join(',').to_s }.uniq.join('/')
        sync_info = args[:options][:adapter].last_synchronization_log
        if sync_info && sync_info.started_at
          sync_info.update(started_at: DateTime.now)
          sync_info.started_at.in_time_zone(TZInfo::Timezone.get(time_zone)).to_datetime.strftime("%Y-%m-%d %H:%M:%S %p")
        else
          "Never"
        end
      }
      property :completed_at, getter: lambda { |args|
        time_zone = args[:options][:current_user].time_zone.map { |_k, v| [v].flatten.join(',').to_s }.uniq.join('/')
        sync_info = args[:options][:adapter].last_synchronization_log
        if sync_info && sync_info.completed_at
          sync_info.completed_at.in_time_zone(TZInfo::Timezone.get(time_zone)).to_datetime.strftime("%Y-%m-%d %H:%M:%S %p")
        else
          "-"
        end
      }

      property :service_sync_status, getter: lambda { |args|
        sync_info = args[:options][:adapter].last_synchronization_log
        unless sync_info.blank?
          unless sync_info.service_sync_status.blank?
            sync_status = sync_info.service_sync_status[args[:options][:adapter].id]
            new_hash = {}
            unless sync_status.nil?
              sync_status.each_pair do |k,v|
                new_hash.merge!({k.downcase => v})
              end
            end
            new_hash
          end
        end
      }

      property :vpc_attributes_labels

      collection(
        :regions,
        extend: ::Synchronizer::AWS::SyncRegionInfoRepresenter
      )

      def regions
        self[:regions]
      end

      def vpc_attributes_labels
        {
          "name" => "VPC Name",
          "provider" => "Provider",
          "adapter_name" => "Adapter",
          "vpc_id" => "VPC ID",
          "cidr" => "CIDR Block",
          "internet_attached" => "Internet attached",
          "tenancy" => "Tenancy",
          "unallocated_services_cost" => "Cost",
          "present_on_aws" => "Present On AWS"
        }
      end

    end
  end
end
