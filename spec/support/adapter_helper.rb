module AdapterHelper

  def create_adapter 
    @adapter_valid_credentials =
      {
        type: "Adapters::AWS",
        name: "Normal adapter",
        margin_discount_calculation: "customer_cost",
        access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
        secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
        bucket_id: "",
        aws_account_id: "",
        bucket_region_id: "",
        adapter_purpose: "normal",
        role_based: false,
        role_arn: "",
        external_id: "",
        sts_region: "",
        is_us_gov: false,
        role_name: "",
        aws_support_discount: "",
        aws_vat_percentage: "",
        report_configuration: {compression_type: "ZIP", status: true},
        service_types_discount: {},
        account_id: @account.id
      }
    
    post '/adapters', params: @adapter_valid_credentials.to_json, headers: valid_headers
    expect(response).to have_http_status(201)
    @adapter_id = JSON.parse(response.body)['id']

  end 
end 

RSpec.configure do |config|
  config.include AdapterHelper, type: :request
end