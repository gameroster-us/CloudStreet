# spec/requests/gcp_controller_spec.rb

require 'rails_helper'

RSpec.describe 'AdapterController', type: :request do
  
  before(:all) do
    WebMock.disable!
  end

  describe 'GCP Adapter all possible cases' do
    let(:valid_credentials) do
        {
          type: 'Adapters::GCP',
          gcp_access_keys: ENV.fetch('GCP_ACCESS_KEYS'),
          adapter_purpose: 'billing',
          dataset_id: ENV.fetch('DATASET_ID'),
          table_name: ENV.fetch('TABLE_NAME')
        }
    end
    before do
      create_session_for_billing_adapter(Adapters::GCP)
    end

    def valid_headers
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'web-host' => "#{@organisation&.subdomain || 'default'}.#{@company_domain}"
      }.merge(authorization_header)
    end
  
    def authorization_header
      {
        'Authorization' => "Bearer #{generate_jwt_token(@user, @organisation)}"
      }
    end
    context 'POST /adapters/credential_verifier for GCP Billing adapter' do
      context 'when credentials are correct for gcp normal  adapter' do
        it 'returns a success response when valid gcp access keys' do
          post '/adapters/credential_verifier', params: valid_credentials.merge({adapter_purpose: 'normal',dataset_id: "",table_name: ""}).to_json, headers: valid_headers
          expect(response).to have_http_status(:success)
        end
      end
      context 'when credentials are correct for gcp billing  adapter' do
        it 'returns a success response when valid dataset id and gcp access keys and table name' do
          post '/adapters/credential_verifier', params: valid_credentials.to_json, headers: valid_headers
          expect(response).to have_http_status(:success)
        end
      end

      context 'when credentials are incorrect gcp for billing adapter' do
        let(:invalid_credentials) do
          valid_credentials.merge(dataset_id: 'invalid_key',gcp_access_keys: "invalid_key",table_name: "invalid_key")
        end

        it 'returns an error response when invalid dataset id and gcp access keys and table name' do
          post '/adapters/credential_verifier', params: invalid_credentials.to_json, headers: valid_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
        it 'returns an error response when invalid dataset id and valid gcp access keys and valid table name' do
          post '/adapters/credential_verifier', params: valid_credentials.merge!({dataset_id: 'invalid_key'}).to_json, headers: valid_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
        it 'returns an error response when valid dataset id and invalid gcp access keys and valid table name' do
          post '/adapters/credential_verifier', params: valid_credentials.merge!({gcp_access_keys: 'invalid_key'}).to_json, headers: valid_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
        it 'returns an error response when valid dataset id and valid gcp access keys and invalid table name' do
          post '/adapters/credential_verifier', params: valid_credentials.merge!({table_name: 'invalid_key'}).to_json, headers: valid_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
        xit 'returns an error response when invalid type' do
          post '/adapters/credential_verifier', params: valid_credentials.merge!({type: 'invalid_type'}).to_json, headers: valid_headers
          expect(response).to have_http_status(500)
        end
      end
    end
    context 'POST /adapters Normal Adapter' do
      let(:adapter_params) do
        {
          name: 'Normal GCP Adapter',
          adapter_purpose: 'normal',
          type: 'Adapters::GCP',
          gcp_access_keys: ENV.fetch('GCP_ACCESS_KEYS'),
          is_linked_account: '',
          margin_discount_calculation: 'customer_cost'
        }
      end
      context 'when credentials are correct and creating normal adapter and checking validations' do
        before do
          @job_count = SyncWorker.jobs.count
          post '/adapters', params: adapter_params.to_json, headers: valid_headers
          expect(response).to have_http_status(201)
          @adapter_id = JSON.parse(response.body)['id']
          expect(@adapter_id).not_to be_nil
        end
        it 'returns 201 when normal adapter created sucessfully' do
          expect(response).to have_http_status(201)
        end
        it "Increment the job count by 1 when the auto-sync functionality is triggered after creating a normal GCP adapter." do
          expect(SyncWorker.jobs.count).to eq(@job_count + 1)
        end
        it 'returns status 422  when creating with same invalid gcp access key' do
          post '/adapters', params: adapter_params.merge({name: "invalid gcp key",gcp_access_keys: "invalid_keys"}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["validation_errors"][0][1]).to eq(["Credentials are invalid."])
        end
        it 'returns status 422  when creating with same name adapter with gcp project as no' do
          post '/adapters', params: adapter_params.merge({is_linked_account: true}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["validation_errors"][0][1]).to eq(["Adapter Name is already in use"])
        end
        it 'returns status 422  when creating with same name adapter with gcp project as yes' do
          post '/adapters', params: adapter_params.merge({is_linked_account: true}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["validation_errors"][0][1]).to eq(["Adapter Name is already in use"])
        end
        it 'returns staus 422  when creating new adapter with empty name ' do
          post '/adapters', params: adapter_params.merge({name: ""}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expected_substring = "can't be blank"
          expect(parsed_response["validation_errors"].to_s).to include(expected_substring)
          expected_substring2 = "project id is already in use with adapter"
          expect(parsed_response["validation_errors"].to_s).to include(expected_substring2)
        end
        it 'returns staus 422  when creating with same GCP account id ' do
          post '/adapters', params: adapter_params.merge!({name: 'updated normal adapter'}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expected_substring = "project id is already in use with adapter"
          expect(parsed_response["validation_errors"].to_s).to include(expected_substring)
        end
        it "Returns true if the adapter's sync_running attribute is true for a normal adapter." do
          expect(Adapter.find(@adapter_id).sync_running).to be true
        end
        it "The state is returned as 'active' when the synchronization notification for the GCP adapter is successful." do
          expect(Adapter.find(@adapter_id).state).to eq("active")
        end
        it 'returns status 422 when  updates the adapter title with empty name ' do
          post "/adapters/#{@adapter_id}/update", params: { type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expected_substring = "can't be blank"
          expect(parsed_response["validation_errors"].to_s).to include(expected_substring)
        end
        it 'returns status 200 when succesfully updates the adapter title' do
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Title', type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
        end
        it "When the synchronization progress bar for the GCP adapter succeeds, it returns the state as 'active'." do
          expect(Adapter.find(@adapter_id).state).to eq("active")
        end
        it 'returns status 200 when succesfully updates the adapter name with more than 64 characters' do
          post "/adapters/#{@adapter_id}/update", params: { name: Faker::Lorem.characters(number: 100), type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
        end
        it "Returns the state as 'active' when the synchronization process for the GCP adapter is successful." do
          expect(Adapter.find(@adapter_id).state).to eq("active")
        end
        it 'returns status 200 when using invalid gcp details during  update' do
          post "/adapters/#{@adapter_id}/update", params: {name: 'Updated Title with invalid gcp',type: "Adapters::GCP",gcp_access_keys: 'invalid_key'}.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
        end
        it 'returns status 204 when successfully deletes the adapter' do
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(204)
          if Adapter.find(@adapter_id).state == "deleting"
            Adapter.find(@adapter_id).destroy
          end
        end
        xit 'Test synchronization for multiple GCP adapter' do
          puts "will complete this when got other credential fpr normal gcp adapter "
        end
      end
      context 'Test normal adapters linked GCP project as NO after deleting few adapters' do
        it 'it returns status 201 normal adapters linked GCP project as NO after deleting few adapters' do
          post '/adapters', params: adapter_params.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
          @adapter_id = JSON.parse(response.body)['id']
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
            if Adapter.find(@adapter_id).state == "deleting"
              Adapter.find(@adapter_id).destroy
            end
            post '/adapters', params: adapter_params.to_json, headers: valid_headers.merge!(authorization_header)
            expect(response).to have_http_status(201)
            @adapter_id = JSON.parse(response.body)['id']
            Adapter.find(@adapter_id).update(sync_running: false)
            put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
              if Adapter.find(@adapter_id).state == "deleting"
                Adapter.find(@adapter_id).destroy
              end
            post '/adapters', params: adapter_params.merge({is_linked_account: false}).to_json, headers: valid_headers.merge!(authorization_header)
            expect(response).to have_http_status(201)
        end
        it 'it returns status 201 normal adapters linked GCP project as NO after deleting few adapters' do
          post '/adapters', params: adapter_params.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
          @adapter_id = JSON.parse(response.body)['id']
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
            if Adapter.find(@adapter_id).state == "deleting"
              Adapter.find(@adapter_id).destroy
            end
            post '/adapters', params: adapter_params.to_json, headers: valid_headers.merge!(authorization_header)
            expect(response).to have_http_status(201)
            @adapter_id = JSON.parse(response.body)['id']
            Adapter.find(@adapter_id).update(sync_running: false)
            put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
              if Adapter.find(@adapter_id).state == "deleting"
                Adapter.find(@adapter_id).destroy
              end
            post '/adapters', params: adapter_params.merge({is_linked_account: true}).to_json, headers: valid_headers.merge!(authorization_header)
            expect(response).to have_http_status(201)
        end
      end
    end
    context 'POST /adapters for Billing Adapter' do
      context 'when credentials are correct and creating billing adapter and checking validations' do
        let(:valid_attributes) do
          {
            name: 'Billing GCP Adapter',
            adapter_purpose: 'billing',
            type: 'Adapters::GCP',
            gcp_access_keys: ENV.fetch('GCP_ACCESS_KEYS'),
            is_linked_account: false,
            enable_invoice_date: true,
            invoice_date: 10,
            margin_discount_calculation: 'cost',
            table_name: ENV.fetch('TABLE_NAME'),
            dataset_id: ENV.fetch('DATASET_ID')
          }
        end
        before do
          post '/adapters', params: valid_attributes.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)

          @adapter_id = JSON.parse(response.body)['id']
          expect(@adapter_id).not_to be_nil
        end
        it 'returns 201 when billing adapter created sucessfully' do
          expect(response).to have_http_status(201)
        end
        it 'returns 201 when billing adapter created without when invoice is false' do
          post '/adapters', params: valid_attributes.merge!({name: "invoice false",enable_invoice_date: false, invoice_date: ""}).to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
        end
        it 'returns status 422  when creating with same name billing adapter' do
          post '/adapters', params: valid_attributes.to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(422)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["validation_errors"][0][1]).to eq(["Adapter Name is already in use"])
        end
        it 'returns 201 when creating with same GCP account id ' do
          post '/adapters', params: valid_attributes.merge!({name: 'updated billing adapter'}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
        end
        it 'returns 201 when creating gcp billing account with is link account gcp project true' do
          post '/adapters', params: valid_attributes.merge!({name: 'link account billing adapter',is_linked_account: true}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
        end
        it 'returns 201 when creating gcp billing account with is link account true' do
          post '/adapters', params: valid_attributes.merge!({name: 'link account billing adapter',is_linked_account: false}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
        end
        it 'returns 201 when creating adapter with margin discount calculation as customer cost' do
          post '/adapters', params: valid_attributes.merge!({name: 'adapter with customer cost',margin_discount_calculation: 'customer_cost'}).to_json, headers:  valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(201)
        end
        it 'returns status 200 when succesfully updates the billing adapter is link account yes from no' do
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Billing Title', type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
        end
        it 'returns status 200 when succesfully updates the billing adapter title' do
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Billing Title', type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
        end
        it 'returns status 204 when successfully deletes the adapter' do
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::AWS" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(204)
          if Adapter.find(@adapter_id).state == "deleting"
            Adapter.find(@adapter_id).destroy
          end
        end
      end
    end
  end
  describe 'POST /adapters when permission is not given' do
    let(:valid_credentials) do
      {
        type: 'Adapters::GCP',
        gcp_access_keys: ENV.fetch('GCP_ACCESS_KEYS'),
        adapter_purpose: 'billing',
        dataset_id: ENV.fetch('DATASET_ID'),
        table_name: ENV.fetch('TABLE_NAME')
      }
  end
    def valid_headers
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'web-host' => "#{@organisation&.subdomain || 'default'}.#{@company_domain}"
      }.merge(authorization_header)
    end

    def authorization_header
      {
        'Authorization' => "Bearer #{generate_jwt_token(@user, @organisation)}"
      }
    end
      before do
        @user = create(:user)
        @application_plan = create(:application_plan)
        @organisation = create(:organisation,user_id: @user.id, application_plan_id: @application_plan.id)
        @organisation_user = create(:organisation_user, user: @user, organisation: @organisation)
        @tenant = create(:tenant, organisation: @organisation, is_default: true)
        @tenant_user = create(:tenant_user, user: @user, tenant: @tenant)
        @account = create(:account, organisation: @organisation)
        @regions_map = Region::MAP
        @adapter_create = create(:adapter, :gcp, state: "directory",account_id: @account.id)
        @gcp_adapters = Adapter.directoried.select { |adapter| adapter.is_a?(Adapters::GCP) }
        @region = create(:region, code: "us-west-2",adapter_id: @gcp_adapters.first.id)
        @account_region = create(:account_region, account: @account, enabled: true, region_id: @region.id)
        @user_role = @user.user_roles.new(name: "Administrator", organisation_id: @organisation.id)
        @user_role.save
        @user.user_roles_users.create(user_role_id: @user_role.id, tenant_id: @tenant.id, user_id: @user.id)
        @company_domain = Faker::Internet.domain_name
        create_params = {
          username: @user.username,
          password: @user.password,
          host: "#{@organisation.subdomain}.#{@company_domain}"
        }
        post private_sessions_path, params: create_params
    end
    let(:adapter_params) do
      {
        name: 'Normal GCP Adapter',
        adapter_purpose: 'normal',
        type: 'Adapters::GCP',
        gcp_access_keys: ENV.fetch('GCP_ACCESS_KEYS'),
        is_linked_account: '',
        margin_discount_calculation: 'customer_cost'
      }
    end
    context 'covering sucess and failure scenerios of permission to create adapter' do
      it'return failure when creating Adapter with no permission of create adapter' do
      rights = ["cs_adapter_view"]
      rights.each do |right|
        @access_right = create(:access_right, title: "Manage", code: right)
        @access_right_user_role = AccessRightsUserRoles.create(user_role_id: @user_role.id, access_right_id: @access_right.id)
      end
        post '/adapters', params: adapter_params.to_json, headers: valid_headers
        expect(response).to have_http_status(403)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["message"]).to eq("You are not authorized to complete that action")
      end
      it'return success when creating Adapter with  permission of create adapter' do
        rights = ["cs_adapter_view","cs_adapter_create"]
        rights.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = AccessRightsUserRoles.create(user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
          post '/adapters', params: adapter_params.to_json, headers: valid_headers
          expect(response).to have_http_status(201)
      end
      it'return failure when creating Adapter with  permission of create adapter but not having edit permission' do
        rights = ["cs_adapter_view","cs_adapter_create"]
        rights.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = AccessRightsUserRoles.create(user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
          post '/adapters', params: adapter_params.to_json, headers: valid_headers
          expect(response).to have_http_status(201)
          @adapter_id = JSON.parse(response.body)['id']
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Title', type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(403)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["message"]).to eq("You are not authorized to complete that action")
      end
      it'return success when creating Adapter with  permission of create adapter and having edit permission' do
        rights = ["cs_adapter_view","cs_adapter_create","cs_adapter_edit"]
        rights.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = AccessRightsUserRoles.create(user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
          post '/adapters', params: adapter_params.to_json, headers: valid_headers
          expect(response).to have_http_status(201)
          @adapter_id = JSON.parse(response.body)['id']
          post "/adapters/#{@adapter_id}/update", params: { name: 'Updated Title', type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(200)
      end
      it'return failure when creating Adapter with  permission of create adapter but not having deletion permission' do
        rights = ["cs_adapter_view","cs_adapter_create"]
        rights.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = AccessRightsUserRoles.create(user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
          post '/adapters', params: adapter_params.to_json, headers: valid_headers
          expect(response).to have_http_status(201)
          @adapter_id = JSON.parse(response.body)['id']
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(403)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["message"]).to eq("You are not authorized to complete that action")
      end
      it'return success when creating Adapter with  permission of create adapter and having deletion permission' do
        rights = ["cs_adapter_view","cs_adapter_create","cs_adapter_delete"]
        rights.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = AccessRightsUserRoles.create(user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
          post '/adapters', params: adapter_params.to_json, headers: valid_headers
          expect(response).to have_http_status(201)
          @adapter_id = JSON.parse(response.body)['id']
          Adapter.find(@adapter_id).update(sync_running: false)
          put "/adapters/#{@adapter_id}/destroy", params: { type: "Adapters::GCP" }.to_json, headers: valid_headers.merge!(authorization_header)
          expect(response).to have_http_status(204)
      end
    end
  end
end
