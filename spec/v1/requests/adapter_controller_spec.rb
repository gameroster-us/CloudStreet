# spec/requests/adapter_controller_spec.rb

require 'rails_helper'

RSpec.describe 'AdapterController', type: :request do
  let(:valid_credentials) do
    {
      "type": "Adapters::AWS",
      "name": "Normal adapter",
      "margin_discount_calculation": "customer_cost",
      "access_key_id": ENV.fetch('AWS_ACCESS_KEY_ID'),
      "secret_access_key": ENV.fetch('AWS_SECRET_ACCESS_KEY'),
      "bucket_id": "",
      "aws_account_id": "",
      "bucket_region_id": "",
      "adapter_purpose": "normal",
      "role_based": false,
      "role_arn": "",
      "external_id": "",
      "sts_region": "",
      "is_us_gov": false,
      "role_name": "",
      "aws_support_discount": "",
      "aws_vat_percentage": "",
      "report_configuration": {"compression_type"=>"ZIP", "status"=>true},
      "service_types_discount": {},
      "account_id": @account.id
    }
  end
  # let(:role_based_valid_credentials) do
  #   valid_credentials.merge(role_based: true, role_arn: "arn:aws:iam::707082674943:role/DevQALocalFullAccess", sts_region: "us-west-2")
  # end
  # let(:role_based_invalid_credentials) do
  #   valid_credentials.merge(role_based: true, role_arn: "arn:aws:iam::707082674943:role/DevQALocalFullAccesssss", sts_region: "us-west-2")
  # end

  before do
    create_session_for_billing_adapter(Adapters::AWS)
  end

  def valid_headers
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'web-host' => "#{@organisation.subdomain}.#{@company_domain}"
    }.merge(authorization_header)
  end

  def authorization_header
    {
      'Authorization' => "Bearer #{generate_jwt_token(@user, @organisation)}"
    }
  end
  describe 'POST /adapters/credential_verifier for both Normal and Billing adapter and backup adapter' do
    context 'when credentials are correct for normal adapter' do
      it 'returns a success response when valid access key id and secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.to_json, headers: valid_headers
        expect(response).to have_http_status(:success)
      end
      # it 'returns a success response when role based adapters credential are valid Role ARN and Account ID' do
      #   post '/adapters/credential_verifier', params: role_based_valid_credentials.to_json, headers: valid_headers
      #   expect(response).to have_http_status(:success)
      # end
    end

    context 'when credentials are incorrect for normal adapter' do
      let(:invalid_credentials) do
        valid_credentials.merge(access_key_id: 'invalid_key',secret_access_key: "invalid_key")
      end

      it 'returns an error response when invalid access key id and secret_access_key' do
        post '/adapters/credential_verifier', params: invalid_credentials.to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when invalid access key id and valid secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({access_key_id: 'invalid_key'}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when valid access key id and invalid secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({secret_access_key: 'invalid_key'}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      # it 'returns an error response when role based adapters credential are valid Role ARN and Account ID' do
      #   post '/adapters/credential_verifier', params: role_based_invalid_credentials.to_json, headers: valid_headers
      #   expect(response).to have_http_status(:unprocessable_entity)
      # end
    end

    context 'when credentials are correct for billing adapter' do
      it 'returns a success response when valid access key id and secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({access_key_id: ENV.fetch('AWS_BILLING_ACCESS_KEY_ID'),secret_access_key: ENV.fetch('AWS_BILLING_SECRET_ACCESS_KEY'),adapter_purpose: "billing"}).to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when credentials are incorrect for billing adapter' do
      let(:invalid_credentials) do
        valid_credentials.merge(access_key_id: 'invalid_key',secret_access_key: "invalid_key",adapter_purpose: "billing")
      end

      it 'returns an error response when invalid access key id and secret_access_key' do
        post '/adapters/credential_verifier', params: invalid_credentials.to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when invalid access key id and valid secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({access_key_id: 'invalid_key'}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when valid access key id and invalid secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({secret_access_key: 'invalid_key'}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      # it 'returns an error response when role based adapters credential are valid Role ARN and Account ID' do
      #   post '/adapters/credential_verifier', params: role_based_invalid_credentials.to_json, headers: valid_headers
      #   expect(response).to have_http_status(:unprocessable_entity)
      # end
    end
    context 'when credentials are correct for backup adapter' do
      it 'returns a success response when valid access key id and secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),adapter_purpose: "backup"}).to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(:success)
      end
    end
    context 'when credentials are incorrect for backup adapter' do
      let(:invalid_credentials) do
        valid_credentials.merge(access_key_id: 'invalid_key',secret_access_key: "invalid_key",adapter_purpose: "backup")
      end
      it 'returns an error response when invalid access key id and secret_access_key' do
        post '/adapters/credential_verifier', params: invalid_credentials.to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when invalid access key id and valid secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({access_key_id: 'invalid_key',adapter_purpose: "backup"}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when valid access key id and invalid secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({secret_access_key: 'invalid_key',adapter_purpose: "backup"}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  describe 'POST /adapters Normal Adapter' do
    context 'when credentials are correct and creating normal adapter and checking validations' do
      before do
        post '/adapters', params: valid_credentials.to_json, headers: valid_headers
        expect(response).to have_http_status(201)

        @adapter_id = JSON.parse(response.body)['id']
        expect(@adapter_id).not_to be_nil
      end
      it 'returns 201 when normal adapter created sucessfully' do
        expect(response).to have_http_status(201)
      end
      it 'returns status 422  when creating with same name adapter' do
        post '/adapters', params: valid_credentials.to_json, headers:  valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(422)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["validation_errors"][0][1]).to eq(["Adapter Name is already in use"])
      end
      it 'returns staus 422  when creating with same AWS account id ' do
        post '/adapters', params: valid_credentials.merge!({name: 'updated normal adapter'}).to_json, headers:  valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(422)
        parsed_response = JSON.parse(response.body)
        expected_substring = "AWS Account Id is already in use with adapter"
        expect(parsed_response["validation_errors"].to_s).to include(expected_substring)
      end
      it 'returns true when adapter syn_running is true for normal adapter' do
        expect(Adapter.find(@adapter_id).sync_running).to be true
      end
      it 'returns status 200 when succesfully updates the adapter title' do
        Adapter.find(@adapter_id).update(sync_running: false)
        post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Title', type: "Adapters::AWS" }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(200)
      end
      it 'returns status 204 when successfully deletes the adapter' do
        Adapter.find(@adapter_id).update(sync_running: false)
        put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::AWS" }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(204)
      end

      context 'Test Permission' do 
        before do
          AccessRight.find_by(title: 'csROLE', code: 'cs_adapter_delete')&.destroy
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::AWS" }.to_json, headers: valid_headers.merge!(authorization_header)
        end
        
        it_behaves_like 'test status code 403' 

        it_behaves_like 'validate not authorized message'
      end 

      context 'Test Permission' do 
        before do
          AccessRight.find_by(title: 'csROLE', code: 'cs_adapter_create')&.destroy
          post '/adapters', params: valid_credentials.merge(name: 'ChangeName').to_json, headers: valid_headers
        end
        
        it_behaves_like 'test status code 403' 

        it_behaves_like 'validate not authorized message'
      end 

      context 'Test Permission' do 
        before do
          AccessRight.find_by(title: 'csROLE', code: 'cs_adapter_edit')&.destroy
          Adapter.find(@adapter_id).update(sync_running: false)
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Title', type: "Adapters::AWS" }.to_json, headers: valid_headers.merge!(authorization_header)
        end 
        
        it_behaves_like 'test status code 403' 

        it_behaves_like 'validate not authorized message'
      end 
    end
  end

  describe 'POST /adapters for Billing Adapter' do
    context 'when credentials are correct and creating billing adapter and checking validations' do
      let(:valid_attributes) do
        {   name: 'Billing Adapter',
            type: 'Adapters::AWS',
            adapter_purpose: 'billing',
            role_based: false,
            is_us_gov: false,
            report_configuration: {
              report_name: "cost_usage_report",
              report_prefix: "report",
              compression_type: "ZIP",
              s3_bucket: "CSreports-us-west-2",
              s3_region: "us-west-2",
              status: true
            },
            linked_adapter_sts_region: 'us-west-2',
            secret_access_key: ENV.fetch('AWS_BILLING_SECRET_ACCESS_KEY'),
            access_key_id: ENV.fetch('AWS_BILLING_ACCESS_KEY_ID'),
            account_setup: "No"
          }
      end
      before do
        stub_request(:post, "https://cloudtrail.us-east-1.amazonaws.com/")
          .with(
            body: '{}',
            headers: {
              'Content-Type' => 'application/x-amz-json-1.1'
            }
          )
          .to_return(status: 200, body: "{}", headers: {})
        post '/adapters', params: valid_attributes.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(201)

        @adapter_id = JSON.parse(response.body)['id']
        expect(@adapter_id).not_to be_nil
      end
      it 'returns 201 when billing adapter created sucessfully' do
        expect(response).to have_http_status(201)
      end
      it 'returns 201 when billing adapter created without using report configuration ' do
        post '/adapters', params: valid_attributes.merge!({name: "report config empty",report_configuration: {
          report_name: "",
          report_prefix: "",
          compression_type: "ZIP",
          s3_bucket: "",
          s3_region: "",
          status: true
        }}).to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(201)
      end
      it 'returns 201 when billing adapter created with existing report' do
        report_params = {
          region_id: "",
          external_id: "",
          secret_access_key: ENV.fetch('AWS_BILLING_SECRET_ACCESS_KEY'),
          access_key_id: ENV.fetch('AWS_BILLING_ACCESS_KEY_ID'),
          type: 'Adapters::AWS',
          default_config: true
        }
        post '/adapters/get_report_names', params: report_params.to_json, headers: valid_headers.merge!(authorization_header)
        @existing_report = JSON.parse(response.body)
        post '/adapters', params: valid_attributes.merge!({name: 'config existing billing adapter',report_configuration: {
          report_name: @existing_report['result'][0]['report_name'],
          report_prefix: @existing_report['result'][0]['report_prefix'],
          compression_type: @existing_report['result'][0]['compression_type'],
          s3_bucket: @existing_report['result'][0]['s3_bucket'],
          s3_region: @existing_report['result'][0]['s3_region'],
          status: true
        }}).to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(201)

        expect(@adapter_id).not_to be_nil

      end
      it 'returns status 422  when creating with same name billing adapter' do
        post '/adapters', params: valid_attributes.to_json, headers:  valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(422)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["validation_errors"][0][1]).to eq(["Adapter Name is already in use"])
      end
      it 'returns 201 when creating with same AWS account id ' do
        post '/adapters', params: valid_attributes.merge!({name: 'updated billing adapter'}).to_json, headers:  valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(201)
      end
      it 'returns status 200 when succesfully updates the billing adapter title' do
        Adapter.find(@adapter_id).update(sync_running: false)
        post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Billing Title', type: "Adapters::AWS", report_configuration: [] }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(200)
      end
      it 'returns status 200 when succesfully updates the billing adapter org to yes and invalid role' do
        Adapter.find(@adapter_id).update(sync_running: false)
        post "/adapters/#{@adapter_id}/update", params: { account_setup: "Yes",role_name: "Invalid_role", type: "Adapters::AWS", report_configuration: [] }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(200)
      end
      it 'returns status 204 when successfully deletes the adapter' do
        Adapter.find(@adapter_id).update(sync_running: false)
        put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::AWS" }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(204)
      end
    end
  end
  describe 'POST /adapters Backup Adapter' do
    context 'when credentials are correct and creating Backup adapter and checking validations' do
      before do
        post '/adapters', params: valid_credentials.merge!({adapter_purpose: "backup"}).to_json, headers: valid_headers
        expect(response).to have_http_status(201)

        @adapter_id = JSON.parse(response.body)['id']
        expect(@adapter_id).not_to be_nil
      end
      it 'returns 201 when Backup adapter created sucessfully' do
        expect(response).to have_http_status(201)
      end
      it 'returns status 422  when creating with same name Backup' do
        post '/adapters', params: valid_credentials.merge!({adapter_purpose: "backup"}).to_json, headers:  valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(422)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["validation_errors"][0][1]).to eq(["Adapter Name is already in use"])
      end
      it 'returns staus 201  when creating with same AWS account id ' do
        post '/adapters', params: valid_credentials.merge!({adapter_purpose: "backup",name: 'updated normal adapter'}).to_json, headers:  valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(201)
      end
      it 'returns status 200 when succesfully updates the Backup adapter title' do
        Adapter.find(@adapter_id).update(sync_running: false)
        post "/adapters/#{@adapter_id}/update", params: {adapter_purpose: "backup", name: 'Updated Title', type: "Adapters::AWS" }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(200)
      end
      it 'returns status 204 when successfully deletes the Backup adapter' do
        Adapter.find(@adapter_id).update(sync_running: false)
        put "/adapters/#{@adapter_id}/destroy", params: { adapter_purpose: "backup",type: "Adapters::AWS" }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(204)
      end
    end
  end
end
