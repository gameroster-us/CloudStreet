# spec/requests/adapter_controller_spec.rb

require 'rails_helper'

RSpec.describe 'AdapterController', type: :request do
  let(:valid_credentials) do
    {
      type: 'Adapters::Azure',
      adapter_purpose: 'normal',
      azure_account_type: '',
      mgmt_credentials: {},
      azure_cloud: 'AzureCloud',
      tenant_id: ENV.fetch('AZURE_NORMAL_BILLING_TENANT_ID'),
      secret_key: ENV.fetch('AZURE_NORMAL_BILLING_SECRET_KEY'),
      client_id: ENV.fetch('AZURE_NORMAL_BILLING_CLIENT_ID')
  }
  end

  let(:valid_credentials_billing) do
    {
      type: 'Adapters::Azure',
      adapter_purpose: 'billing',
      azure_account_type: '',
      mgmt_credentials: {},
      azure_cloud: 'AzureCloud',
      tenant_id: ENV.fetch('AZURE_BILLING_TENANT_ID'),
      secret_key: ENV.fetch('AZURE_BILLING_SECRET_KEY'),
      client_id: ENV.fetch('AZURE_BILLING_CLIENT_ID')
  }
  end

  before do
    create_session_for_billing_adapter(Adapters::Azure)
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
  describe 'POST /adapters/credential_verifier for both Normal and Billing adapter' do
    context 'when credentials are correct for normal adapter' do
      it 'returns a success response when valid access key id and secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.to_json, headers: valid_headers
        p '---------------------------------------------'
        p JSON.parse(response.body)
        p JSON.parse(response.body)
        p '---------------------------------------------'
        expect(response).to have_http_status(:success)
        @subscription_data = JSON.parse(response.body)['data'][0]
      end
    end

    context 'when credentials are incorrect for normal adapter' do
      let(:invalid_credentials) do
        valid_credentials.merge(secret_key: 'invalid_key',tenant_id: "invalid_key",client_id: "invalid_key")
      end

      it 'returns an error response when invalid  secret_key id and tenant id and client id' do
        post '/adapters/credential_verifier', params: invalid_credentials.to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when invalid secret key id and valid tenant id and client id' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({secret_key: 'invalid_key'}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when valid secret key id and valid tenant id and invalid client id' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({client_id: 'invalid_key'}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'returns an error response when valid secret key id and valid client id and invalid tenant id' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({tenant_id: 'invalid_key'}).to_json, headers: valid_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when credentials are correct for billing adapter' do
      it 'returns a success response when valid access key id and secret_access_key' do
        post '/adapters/credential_verifier', params: valid_credentials.merge!({adapter_purpose: "billing",azure_account_type: "ss"}).to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(:success)
      end
    end
  end
  describe 'POST /adapters Normal Adapter' do
    context 'when credentials are correct and creating normal adapter and checking validations' do
      let(:subscription_data_normal) do
        credential_verifier(valid_credentials, valid_headers)
      end
      let(:adapter_params) do
        {
          name: 'Normal Adapter',
          type: 'Adapters::Azure',
          adapter_purpose: 'normal',
          azure_account_type: '',
          deployment_model: 'arm',
          account_setup: true,
          ea_account_setup: 'No',
          is_management_credentials: 'No',
          multi_tenant_setup: false,
          multiple_tenant_details: [],
          currency: 'USD',
          mgmt_credentials: {},
          azure_cloud: 'AzureCloud',
          pec_calculation: '1',
          tenant_id: ENV.fetch('AZURE_NORMAL_BILLING_TENANT_ID'),
          secret_key: ENV.fetch('AZURE_NORMAL_BILLING_SECRET_KEY'),
          client_id: ENV.fetch('AZURE_NORMAL_BILLING_CLIENT_ID'),
          subscription_id: subscription_data_normal['subscription_id'],
          invoice_date: '',
          subscription: subscription_data_normal
      }
    end
      before do
        post '/adapters', params: adapter_params.to_json, headers:  valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(201)
        @adapter_id = JSON.parse(response.body)['id']
        expect(@adapter_id).not_to be_nil
      end
      it 'returns 201 when normal adapter created sucessfully' do
        expect(response).to have_http_status(201)
      end
      it 'returns status 422 when creating with same name adapter' do
        post '/adapters', params: adapter_params.to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["validation_errors"][0][1]).to eq(["Adapter Name is already in use"])
      end
      it 'returns staus 422  when creating with same Azure account id ' do
        post '/adapters', params: adapter_params.merge!({name: 'updated normal adapter'}).to_json, headers:  valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(422)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["validation_errors"][0][1].first).to include("subscription is already in use with adapter")
      end
      it 'returns true when adapter syn_running is true for normal adapter' do
        expect(Adapter.find(@adapter_id).sync_running).to be true
      end
      it 'returns status 200 when succesfully updates the adapter title' do
        post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Title', type: "Adapters::Azure" }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(200)
      end
      it 'returns status 204 when successfully deletes the adapter' do
        Adapter.find(@adapter_id).update(sync_running: false)
        put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::Azure" }.to_json, headers: valid_headers.merge!(authorization_header)
        expect(response).to have_http_status(204)
      end
    end
  end

  describe 'POST /adapters for Billing Adapter' do
    context 'when credentials are correct and creating billing adapter and checking validations' do
      let(:subscription_data) do
        credential_verifier(valid_credentials, valid_headers)
      end
      let(:valid_attributes) do
        {
          name: 'billing adapter',
          type: 'Adapters::Azure',
          adapter_purpose: 'billing',
          azure_account_type: 'ss',
          deployment_model: 'arm',
          export_configuration: {
            scope: 'Subscription',
            name: "",
            container: "",
            directory: "",
            storageAccounts:[],
            configuration: [
              {
                name: '',
                container: '',
                directory: '',
                storage_account_id: '',
                scope_id: ''
              }
            ]
          },
          account_setup: false,
          ea_account_setup: 'No',
          is_management_credentials: 'No',
          multiple_tenant_details: [],
          currency: 'USD',
          mgmt_credentials: {},
          azure_cloud: 'AzureCloud',
          pec_calculation: '',
          enable_invoice_date: false,
          invoice_date: '',
          tenant_id: ENV.fetch('AZURE_NORMAL_BILLING_TENANT_ID'),
          secret_key: ENV.fetch('AZURE_NORMAL_BILLING_SECRET_KEY'),
          client_id: ENV.fetch('AZURE_NORMAL_BILLING_CLIENT_ID'),
          subscription: subscription_data
        }
      end
      context 'creating billing azure adapter by creating new configuration' do
        before do
          post '/adapters/get_storage_accounts', params: valid_credentials.merge({scope_id: subscription_data["id"],adapter_purpose: 'billing'}).to_json, headers: valid_headers.merge!(authorization_header)
            @get_storage_accounts = JSON.parse(response.body)
            post '/adapters/create_export_on_azure', params: valid_attributes.merge({export_configuration: {storage_account_id: @get_storage_accounts["result"][0]['id'], scope_id: subscription_data["id"],name: generate_single_word,container: generate_single_word,directory: generate_single_word}}).to_json, headers: valid_headers.merge!(authorization_header)
            @create_export_on_azure = JSON.parse(response.body)
          post '/adapters', params: valid_attributes.merge(
            export_configuration: {
              configuration: [
                storage_account_id: @get_storage_accounts.dig('result', 0, 'id') || ENV.fetch('STORAGE_ACCOUNT_ID'),
                scope_id: subscription_data['id'],
                name: @create_export_on_azure.dig('result', 'data', 'name') || "export_data",
                container: @create_export_on_azure.dig('result', 'data', 'delivery_info','destination', 'container') || 'wgeyxcp',
                directory: @create_export_on_azure.dig('result', 'data', 'delivery_info', 'destination', 'root_folder_path') || 'vznos'
              ]
            }
          ).to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)

          @adapter_id = JSON.parse(response.body)['id']
          expect(@adapter_id).not_to be_nil
        end
        it 'returns 201 when billing adapter created sucessfully' do
          expect(response).to have_http_status(201)
        end
        it 'returns 201 when billing adapter created without using export configuration ' do
          post '/adapters', params: valid_attributes.merge(
            name: "without export config adapter",
            export_configuration: {
              configuration: [
                storage_account_id: @get_storage_accounts.dig('result', 0, 'id') || ENV.fetch('STORAGE_ACCOUNT_ID'),
                scope_id: subscription_data['id'],
                name: "",
                container: "",
                directory: ""
              ]
            }
          ).to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
        end
        it 'returns status 422  when creating with same name billing adapter' do
          post '/adapters', params: valid_attributes.merge({export_configuration: {
            configuration: [
              storage_account_id: @get_storage_accounts.dig('result', 0, 'id') || ENV.fetch('STORAGE_ACCOUNT_ID'),
              scope_id: subscription_data['id'],
              name: "",
              container: "",
              directory: ""
            ]
          }}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["validation_errors"][0][1]).to eq(["Adapter Name is already in use"])
        end
        it 'returns 201 when creating with same Azure account id ' do
          post '/adapters', params: valid_attributes.merge!({name: 'updated billing adapter',export_configuration: {
            configuration: [
              storage_account_id: @get_storage_accounts.dig('result', 0, 'id') || ENV.fetch('STORAGE_ACCOUNT_ID'),
              scope_id: subscription_data['id'],
              name: "",
              container: "",
              directory: ""
            ]
          }}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
        end
        it 'returns status 200 when succesfully updates the billing adapter title' do
          Adapter.find(@adapter_id).update(sync_running: false)
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Billing Title', type: "Adapters::Azure",export_configuration: {
            configuration: [
              storage_account_id: @get_storage_accounts.dig('result', 0, 'id') || ENV.fetch('STORAGE_ACCOUNT_ID'),
              scope_id: subscription_data['id'],
              name: "",
              container: "",
              directory: ""
            ]
          } }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
        end

        it 'returns status 204 when successfully deletes the adapter' do
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::Azure" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(204)
        end
      end
      context 'creating billing azure adapter by exporting old configuration' do
        it 'returns 201 when billing adapter created with existing export configuration' do
          post '/adapters/get_azure_exports_list', params: valid_attributes.merge({export_configuration: {scope_id: subscription_data["id"]}}).to_json, headers: valid_headers.merge!(authorization_header)
          @get_azure_exports_list = JSON.parse(response.body)
          post '/adapters', params: valid_attributes.merge(
            export_configuration: {
              configuration: [
                storage_account_id: @get_azure_exports_list.dig('result', 0, 'id') || ENV.fetch('STORAGE_ACCOUNT_ID'),
                scope_id: subscription_data['id'],
                name: @get_azure_exports_list.dig('result', 0, 'name') || 'azurereport',
                container: @get_azure_exports_list.dig('result', 0, 'properties', 'delivery_info','destination','container') || 'azurecostreport',
                directory: @get_azure_exports_list.dig('result', 0, 'properties', 'delivery_info','destination','root_folder_path') || 'azurecostandusagereport'
              ]
            }
          ).to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
        end
      end
      context 'creating billing adapter when scope is billing account' do
        before do
          post '/adapters/get_scope_item_list', params: valid_credentials_billing.merge({adapter_purpose: 'billing',export_configuration: {scope: "Billing Account"}}).to_json, headers: valid_headers.merge!(authorization_header)
            @get_scope_item_list = JSON.parse(response.body)
            post '/adapters/get_azure_exports_list', params: valid_credentials_billing.merge({export_configuration: {scope: "Billing Account", scope_id: @get_scope_item_list['result'][0]['id']}}).to_json, headers: valid_headers.merge!(authorization_header)
            @get_azure_exports_list = JSON.parse(response.body)
          post '/adapters', params: valid_credentials_billing.merge(
            name:'billing account azure adapter',
            export_configuration: {
              configuration: [
                storage_account_id: @get_azure_exports_list.dig('result', 0, 'properties', 'delivery_info','destination','resource_id') || ENV.fetch('STORAGE_ACCOUNT_ID'),
                scope_id: @get_scope_item_list.dig('result', 0, 'id') || ENV.fetch('SCOPE_ID'),
                name: @get_azure_exports_list.dig('result', 0, 'name') || 'billingAccountExport',
                container: @get_azure_exports_list.dig('result', 0, 'properties', 'delivery_info','destination','container') || 'azurecostreport',
                directory: @get_azure_exports_list.dig('result', 0, 'properties', 'delivery_info','destination','root_folder_path') || 'azurecostandusagereport'
              ]
            }
          ).to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)

          @adapter_id = JSON.parse(response.body)['id']
          expect(@adapter_id).not_to be_nil
        end
        it 'returns 201 when billing adapter created sucessfully' do
          expect(response).to have_http_status(201)
        end

        it 'returns status 200 when succesfully updates the billing adapter title' do
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Billing Title', type: "Adapters::Azure" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
        end

        it 'returns status 204 when successfully deletes the adapter' do
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::Azure" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(204)
        end
      end
      context 'creating billing adapter when account type csp' do
        let(:valid_credentials_csp) do
          {
            id: 'e3897940372409',
            name: 'parent csp adapter',
            type: 'Adapters::Azure',
            adapter_purpose: 'billing',
            azure_account_type: 'csp',
            client_id: ENV.fetch('AZURE_CSP_BILLING_CLIENT_ID'),
            secret_key:ENV.fetch('AZURE_CSP_BILLING_SECRET_KEY'),
            tenant_id: ENV.fetch('AZURE_CSP_BILLING_TENANT_ID'),
            pec_calculation: '1',
            export_configuration: {
              configuration: [
                {
                  name: '',
                  container: '',
                  directory: '',
                  storage_account_id: '',
                  scope_id: ''
                }
              ]
            },
          }
        end
        before do
          post '/adapters', params: valid_credentials_csp.to_json, headers: valid_headers.merge!(authorization_header)
          @adapter_id = JSON.parse(response.body)['id']
          expect(@adapter_id).not_to be_nil
        end

        it 'returns 201 when billing adapter created successfully' do
          expect(response).to have_http_status(201)
        end

        it 'returns status 200 when successfully updates the billing adapter title' do
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Billing Title', type: "Adapters::Azure" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
        end

        it 'returns status 204 when successfully delete the adapter' do
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::Azure" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(204)
        end

        [2, 3].each do |pec_calculation_value|
          it "creates billing adapter with pec_calculation: #{pec_calculation_value}" do
            post '/adapters', params: valid_credentials_csp.merge(
              name: "parent csp adapter #{pec_calculation_value}",
              pec_calculation: pec_calculation_value
            ).to_json, headers: valid_headers.merge!(authorization_header)
            expect(response).to have_http_status(201)
          end
        end
      end
    end
  end
end
