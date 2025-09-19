class AWSSdkWrappers::Athena::Client < AWSSdkWrappers::Client

  attr_accessor :client
  
  MAX_RESULTS_LIMIT = 1000

  def initialize(adapter = nil, region_code = nil,**instance_profile_params)
    attributes = connection_attributes(adapter, region_code, **instance_profile_params)
    @client = Aws::Athena::Client.new(attributes)
    @response = AWSSdkWrappers::Response.new
  end

  def exec_query(query_string, database, workgroup)
    request_params = {
      query_string: query_string,
      query_execution_context: {
        database: database
      },
      work_group: workgroup,
    }
    @client.start_query_execution(request_params)
  end

  def get_results(exec_id, next_token = nil, max_results = nil)
    request_params = { query_execution_id: exec_id }
    request_params.merge!(next_token: next_token) if next_token.present?

    if max_results.present?
      max_results += 1 if next_token.blank?
      max_results = max_results > MAX_RESULTS_LIMIT ? MAX_RESULTS_LIMIT : max_results
      request_params.merge!(max_results: max_results)
    end

    @client.get_query_results(request_params)
  end

end
