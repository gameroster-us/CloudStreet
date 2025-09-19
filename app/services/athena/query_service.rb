class Athena::QueryService
  class << self
    DEFAULT_PAGE_LIMIT = 25
    def parse_athena_response(query_resp)
      return [] unless query_resp.present?
      headers = query_resp[0].data.map { |datum| datum.var_char_value }
      query_resp[1..(query_resp.count - 1)].map do |row|
        Hash[headers.zip(row.data.map(&:var_char_value))]
      end
    end

    def filter_dimension_data(data, dimension)
      begin
        dimension = dimension.underscore.parameterize(separator: '_') if dimension.start_with?('tag_')
        data = data.flatten.pluck(dimension).map {|e| {id: e, name: e}}
        data = data.reject {|record| record if record[:id].blank?}
        data.uniq! {|e| e[:id] }
        return data
      rescue
        []
      end
    end

    def exec(query_string)
      @adapter = Adapters::AWS.get_default_adapter
      query_service = @adapter.athena_query_service(APP_REGION)
      begin
        results = query_service.exec_query(query_string, ATHENA_DATABASE, ATHENA_WORKGROUP)
      rescue Aws::Athena::Errors::ThrottlingException => e
        if e.message.include?('Rate exceeded')
          sleep(rand(5..15))
          retry
        end
      end
      exec_id = results.query_execution_id
      sleep(2)
      status = false
      next_token = nil
      response_data = []
      begin
        loop do
          response = query_service.get_results(exec_id, next_token)
          response_data.concat(response.try(:result_set).try(:rows) || [])
          next_token = response.try(:next_token)
          break if next_token.blank?
        end
        status = true
      rescue Aws::Athena::Errors::InvalidRequestException => e
        if e.message.include?('Query has not yet finished')
          sleep(2)
          retry
        end
        response_data = e.message
      end
      block_given? ? yield(status, response_data) : [status, response_data]
    end
    def exec_with_pagination(query_string, limit, &block)
      limit ||= DEFAULT_PAGE_LIMIT
      exec_id, query_service = generate_exec_id(query_string)

      status = false
      next_token = nil
      response_data = []
      handle_error(response_data) do
        response = query_service.get_results(exec_id, next_token, limit.to_i)
        response_data.concat(response.try(:result_set).try(:rows) || [])
        next_token = response.try(:next_token)
        status = true
      end

      block_given? ? yield(status, response_data, exec_id, next_token) : [status, response_data, exec_id, next_token]
    end

    def results_by_id(exec_id, next_token, limit)
      response_data = []
      status = false

      handle_error(response_data) do
        @adapter ||= Adapters::AWS.get_default_adapter
        query_service = @adapter.athena_query_service(APP_REGION)

        begin
          response = query_service.get_results(exec_id, next_token, limit)
        rescue Aws::Athena::Errors::ThrottlingException => e
          if e.message.include?('Rate exceeded')
            sleep(rand(5..15))
            retry
          end
        end

        rows = response.try(:result_set).try(:rows) || []

        if rows.present? && next_token.present?
          columns = response.result_set.result_set_metadata.column_info.map do |aa|
            Aws::Athena::Types::Datum.new(var_char_value: aa.name)
          end
          columns = Aws::Athena::Types::Row.new(data: columns)
          rows = rows.unshift(columns)
        end

        response_data = rows
        next_token = response.try(:next_token)
        status = true
      end

      [status, response_data, next_token]
    end

    private
      def generate_exec_id(query_string)
        @adapter ||= Adapters::AWS.get_default_adapter
        query_service = @adapter.athena_query_service(APP_REGION)

        begin
          results = query_service.exec_query(query_string, ATHENA_DATABASE, ATHENA_WORKGROUP)
        rescue Aws::Athena::Errors::ThrottlingException => e
          if e.message.include?('Rate exceeded')
            sleep(rand(5..15))
            retry
          end
        end

        [results.query_execution_id, query_service]
      end

      def handle_error(response_data, &block)
        begin
          yield
        rescue Aws::Athena::Errors::InvalidRequestException => e
          if e.message.include?('Query has not yet finished')
            sleep(2)
            retry
          end
          response_data = e.message
        end
      end
  end
end
