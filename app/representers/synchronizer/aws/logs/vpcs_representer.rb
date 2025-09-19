module Synchronizer
  module AWS
    module Logs
      module VpcsRepresenter
        include Roar::JSON
        include Roar::Hypermedia

        property :auto_sync_to_cs, getter: lambda { |args| args[:options][:synchronization].auto_sync_to_cs_from_aws }
        property :adapter_names, getter: lambda { |args| args[:options][:synchronization].adapter_names }
        property :region_names, getter: lambda { |args| args[:options][:synchronization].region_names }
        property :started_at, getter: lambda { |args|
          sync_info = args[:options][:synchronization]
          if sync_info && sync_info.started_at
            sync_info.started_at.strftime CommonConstants::DEFAULT_TIME_FORMATE
          else
            "Never"
          end
        }
        property :completed_at, getter: lambda { |args|
          sync_info = args[:options][:synchronization]
          if sync_info && sync_info.completed_at
            sync_info.completed_at.strftime CommonConstants::DEFAULT_TIME_FORMATE
          else
            "-"
          end
        }

        collection(
          :vpcs,
          class: ServiceSynchronizationHistory,
          extend: ::Synchronizer::AWS::Logs::VpcInfoRepresenter
        )

        def vpcs
          collect
        end
      end
    end
  end
end