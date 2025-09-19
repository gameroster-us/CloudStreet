module Groups
  module AthenaSynchronizer
    module QueryHandler
      ATHENA_GROUP_TABLE_NAME_MAP = {
      AWS: 'account_group',
      Azure: 'subscription_group',
      GCP: 'project_group'
      }.with_indifferent_access.freeze

      AWS_PROVIDER = 'AWS'.freeze
      AZURE_PROVIDER = 'Azure'.freeze
      GCP_PROVIDER = 'GCP'.freeze
      GROUP_PROCESSING_BATCH_SIZE  = 5000.freeze
      ATHENA_INSERTION_BATCH_SIZE = 1000.freeze

      private
      def perform_insertion
        if @group_batch_index.zero? # Re-create the table only before the first batch of groups
          raise(StandardError, "#{table_name} Delete or Create operation failed ") unless recreate_table
        end

        return unless values_array.present?

        values_array.each_slice(ATHENA_INSERTION_BATCH_SIZE).each_with_index do |query_data, i|
          CSLogger.info "==== query lenght #{query_data.join(',').length} ====="
          if query_data.join(',').length >= 262100
            CSLogger.info ">>>> splitting query array <<<<<<"
            query_data.each_slice(query_data.length/2).each_with_index do |splitted_query_data, indx|
              CSLogger.info "====== after split query lenght #{splitted_query_data.join(',').length} ======"
              perform_insertion_operation(splitted_query_data,  i+indx)
            end
          else
            perform_insertion_operation(query_data, i)
          end
        end
      end

      def recreate_table
        CSLogger.info "======= Recreating table #{@table_name} ======="
        delete_status = delete_table
        delete_status ? create_table : false
      end

      def create_table
        Athena::QueryService.exec(table_creation_query) do |status, response|
          if status
            CSLogger.info("[Info] : table #{@table_name} created successfully!!!")
          else
            CSLogger.error("[Error] : Something went wrong while table creation!!! table : #{@table_name} | Response : #{response}")
            raise(StandardError, "#{table_name} - table creation failed for organisation identifier #{@org_identifier}")

          end
          return status

        end
      rescue StandardError => e
        notify_honeybadger(e.message, :create)
        false
      end

      def table_creation_query
        if @provider.eql?(AWS_PROVIDER)
          # columns = "`group_name` string, `account_id` string"
          columns = if @feature_enabled
            "`group_name` string, `account_id` string, `tags_data` array<struct<key:string,value:string>>, `tags_data_not_in` array<struct<key:string,value:string>>, `custom_data` array<struct<key:string,value:string>>, `tag_query_operator` string"
          else
            "`group_name` string, `account_id` string, `tags_data` array<struct<key:string,value:string>>, `custom_data` array<struct<key:string,value:string>>"
          end
          path = "s3://#{PARQUET_REPORT_BUCKET}/#{org_identifier}/account_group"
          "CREATE TABLE IF NOT EXISTS #{ATHENA_DATABASE}.#{org_identifier}_account_group(#{columns}) LOCATION '#{path}' TBLPROPERTIES ( 'table_type' = 'ICEBERG' )"
        elsif @provider.eql?(AZURE_PROVIDER)
          columns = "`group_name` string, `subscription_id` string, `tags_data` array<struct<key:string,value:string>>, `custom_data` array<struct<key:string,value:string>>"
          path = "s3://#{PARQUET_REPORT_BUCKET}/#{org_identifier}/subscription_group"
          "CREATE TABLE IF NOT EXISTS #{ATHENA_DATABASE}.#{org_identifier}_subscription_group(#{columns}) LOCATION '#{path}' TBLPROPERTIES ( 'table_type' = 'ICEBERG' )"
        elsif @provider.eql?(GCP_PROVIDER)
          columns = "`group_name` string, `project_id` string, `sub_account_id` string"
          path = "s3://#{PARQUET_REPORT_BUCKET}/#{org_identifier}/project_group"
          "CREATE TABLE IF NOT EXISTS #{ATHENA_DATABASE}.#{org_identifier}_project_group(#{columns}) LOCATION '#{path}' TBLPROPERTIES ( 'table_type' = 'ICEBERG' )"
        end
      end

      def delete_table
        begin
          table_group_name = ATHENA_GROUP_TABLE_NAME_MAP[@provider]
          Athena::QueryService.exec("DROP TABLE `#{table_name}`") do |query_status, response|
            if query_status
              adapter = Adapters::AWS.get_default_adapter
              s3_client = AWSSdkWrappers::S3::Client.new(adapter, ENV['APP_REGION']).client
              s3 = Aws::S3::Resource.new(client: s3_client)
              objects = s3.bucket(PARQUET_REPORT_BUCKET).objects({prefix: "#{org_identifier}/#{table_group_name}"})
              objects.batch_delete! if objects.any?
              CSLogger.info("[Info] : Table #{table_name} dropped successfully")
            else
              CSLogger.error("[Error] : Unable to drop table #{table_name}, Error: #{response}")
              raise(StandardError, "#{table_name} table - deletion failed for organisation identifier #{@org_identifier}")

            end
            return query_status
          end
        rescue StandardError => e
          notify_honeybadger(e.message, :delete)
          false
        end
      end

      def notify_honeybadger(error_message, action)
        args = {
          organisation: @organisation.subdomain,
          table_name: table_name,
          provider: @provider,
          initiated_from: 'AthenaSynchronizerService',
          operation: action,
          error_message: "#{error_message}"
        }
        Honeybadger.notify(error_class: self.class, error_message: args[:error_message], parameters: args.except(:error_message))
      end

      def perform_insertion_operation(values_array, i)
        begin
          values = values_array.join(',')
          insert_query = "INSERT INTO #{table_name} VALUES #{values}"
          Athena::QueryService.exec(insert_query) do |status, response|
            if status
              CSLogger.info("[Info] : Data inserted to athena table #{table_name} group_batch : #{@group_batch_index} | query_batch : #{i} | type : #{@provider}")
            else
              CSLogger.error("[Error] : Insert query Failed, Error: #{response}")
            end
          end
        rescue StandardError => e
          CSLogger.info("[Error] : ======= Error in Athena-Group insertion operaion for organisation #{@organisation.organisation_identifier} Error : #{e.message}=======")
        end
      end
    end
  end
end
