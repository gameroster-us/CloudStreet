module Parsers
  module Azure
    module Database
      module SQL
        class DBServer < Parsers::Azure::Service
          def initialize(remote_db_server)
            super(remote_db_server)            
          end

          def parse_to_azure_service_params
            remote_db_server_data = @remote_service_object["properties"]
            db_server = super.merge!(
              {
                "kind" => Parsers::Azure::Service.dig(remote_db_server_data, @service_metadata, "", "kind"),
                "administrator_login" => Parsers::Azure::Service.dig(remote_db_server_data, @service_metadata, "", "administrator_login"),
                "external_administrator_login" => Parsers::Azure::Service.dig(remote_db_server_data, @service_metadata, "", "external_administrator_login"),
                "version" => Parsers::Azure::Service.dig(remote_db_server_data, @service_metadata, "", "version")
              }
            )
            CSLogger.info "db_server= #{db_server}"
            db_server
          end
        end
      end
    end
  end
end