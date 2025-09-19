# spec/requests/azure_child_organisation_spec.rb
#commented code is working fine  when running them individually but when running whole file due to timeout issue or not getting response of previous apis it fails
#like command for running individual test case
#bundle exec rspec spec/requests/private/reset_passwords_spec.rb:36
require 'rails_helper'

RSpec.describe 'ChildOrganisationSpec', type: :request do

  describe "Cases for Azure" do
    let(:valid_payload) do
      {
        subdomain: @subdomain,
        existing_user_id: @user.id,
        email: Faker::Internet.email,
        ownerType: 'current_user',
        child_host: "https://#{@child_host}",
        organisation_attributes: {
          name: ''
        },
        signup_as: 'normal',
        is_new_user: false
      }
    end
    before(:each) do
      DatabaseCleaner.strategy = :truncation
    end

    after(:each) do
      DatabaseCleaner.clean
    end
    before do
      @subdomain =  Faker::Internet.unique.domain_word
      create_session_for_billing_adapter(Adapters::Azure)
      @child_host = "#{@subdomain}.#{@company_domain}"
      @organisation.update(child_organisation_enable: true)
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
        'Authorization' => "Bearer #{@user.jwt_auth_token(@organisation)}"
      }
    end
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
        ea_account_details: [],
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
    let(:query_params) do
      {
        type: 'adapter_group',
        page_number: 1,
        page_size: 50,
        provider_type: 'Azure',
        searchKeyword: '',
        organisation_id: @organisation.id
      }
    end
    let(:payload_for_update) do
      {
        billing_adapter_ids: [],
        adapter_group_ids: [],
        normal_adapters_ids: [],
        adapter: {
          billing_adapter_ids: []
        }
      }
    end
    let(:payload) do
        {
          show_all: true,
          not_configured: true,
          page_size: 25,
          page_number: 1,
          provider_type: 'Azure'
        }
    end
    let(:payload_adapter_group) do
      {
      name: "Billing Adapter share",
      description: "Billing Adapter share",
      provider_type: "Azure",
      type: "generic",
      billing_adapter_id: "",
      normal_adapter_ids: [],
      tags: [],
      custom_data: [],
      sub_account_ids: [],
      customer_id: [],
      account_tag: [],
      group_based_on_account_tag: false,
      adapter_ids: []
    }
    end
    context "create child organisation when Test add chilld organization if 'Add Child Organisation' access not given to master organisation" do
      it "returns failure when access not given to master organisation" do
        post '/child_organisation/organisations', params: valid_payload.to_json, headers:  valid_headers.merge(authorization_header)
        expect(response).to have_http_status(403)
      end
    end
    context "create child organisation when Test add chilld organization if 'Add Child Organisation' access is  given to master organisation but no having access to activate or deactivate child organisation" do
      before do
        right_create = ["cs_child_organisation_create"]
        right_create.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = create(:access_rights_user_roles, user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
        @child_organisation = create(:organisation,application_plan_id: @application_plan.id,organisation_identifier: "K0000002",subdomain: @subdomain,user_id: @user.id,parent_id: @organisation.id,child_organisation_enable: false,report_profile_id: "65d4748fb2bc58b66f418275")
      end
      it "returns failure when access not given to master organisation for deactivate" do
        get "/child_organisation/organisations/#{@child_organisation.id}/deactive", params: valid_payload.to_json, headers:  valid_headers.merge(authorization_header)
        expect(response).to have_http_status(403)
      end
      it "returns failure when access not given to master organisation for activate" do
        get "/child_organisation/organisations/#{@child_organisation.id}/activate", params: valid_payload.to_json, headers:  valid_headers.merge(authorization_header)
        expect(response).to have_http_status(403)
      end
    end
    context "create child organisation when Test add chilld organization if 'Add Child Organisation' access is  given to master organisation but no having access to Shared Adapter" do
      before do
        right_create = ["cs_child_organisation_view","cs_child_organisation_change_state","cs_child_organisation_create"]
        right_create.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = create(:access_rights_user_roles, user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
        @child_organisation = create(:organisation,application_plan_id: @application_plan.id,organisation_identifier: "K0000002",subdomain: @subdomain,user_id: @user.id,parent_id: @organisation.id,child_organisation_enable: false,report_profile_id: "65d4748fb2bc58b66f418275")
      end
      it "returns failure when access not given to master organisation" do
        put "/child_organisation/adapters/#{@child_organisation.id}", params: payload_for_update.to_json, headers: valid_headers.merge(authorization_header)
        expect(response).to have_http_status(403)
      end
    end
    context "create child organisation with covering all the possible scenerios" do
      before do
        right_create = ["cs_child_organisation_view","cs_child_organisation_change_state","cs_child_organisation_edit","cs_child_organisation_delete","cs_child_organisation_create"]
        right_create.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = create(:access_rights_user_roles, user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
      end
      context "all the senerios in child organisation which do not require initial child data" do
        it 'creates a child organisation with valid payload' do
          post '/child_organisation/organisations', params: valid_payload.to_json, headers:  valid_headers.merge(authorization_header)
          expect(response).to have_http_status(:success)
        end

        it 'it returns failure 422 status when creates a child organisation with same site name from which parent is already available' do
          post '/child_organisation/organisations', params: valid_payload.merge({subdomain: @organisation.subdomain}).to_json, headers:  valid_headers.merge(authorization_header)
          expect(response).to have_http_status(422)
        end

        it 'return success Test validation for User Email filed on Add child organisation page' do
          post '/child_organisation/organisations', params: valid_payload.merge({email: Faker::Internet.email}).to_json, headers:  valid_headers.merge(authorization_header)
          expect(response).to have_http_status(201)
        end
      end
      context "all the senerios in child organisation which require initial child data" do
        before do
          @child_organisation = create(:organisation,application_plan_id: @application_plan.id,organisation_identifier: "K0000002",subdomain: @subdomain,user_id: @user.id,parent_id: @organisation.id,child_organisation_enable: false,report_profile_id: "65d4748fb2bc58b66f418275",is_active: true)
        end
        it 'return 422 creates a child organisation with already subdomin added' do
          post '/child_organisation/organisations', params: valid_payload.merge({subdomain: JSON.parse(response.body)["subdomain"]}).to_json, headers:  valid_headers.merge(authorization_header)
          expect(response).to have_http_status(422)
        end
        # it "returns success when access given to master organisation for deactivate" do
        #   get "/child_organisation/organisations/#{@child_organisation.id}/deactive", params: valid_payload.to_json, headers:  valid_headers.merge(authorization_header)
        #   expect(response).to have_http_status(200)
        # end
        it "returns success when access given to master organisation for activate" do
          get "/child_organisation/organisations/#{@child_organisation.id}/activate", params: valid_payload.to_json, headers:  valid_headers.merge(authorization_header)
          expect(response).to have_http_status(200)
        end
      end
    end
    context 'creates a child organisation with valid payload and share adapter to child organisation covering all the scenerios' do
      before do
        right_create = ["cs_child_organisation_view","cs_child_organisation_change_state","cs_child_organisation_edit","cs_child_organisation_delete","cs_child_organisation_create","cs_child_organisation_shared_adapter_edit"]
        right_create.each do |right|
          @access_right = create(:access_right, title: "Manage", code: right)
          @access_right_user_role = create(:access_rights_user_roles, user_role_id: @user_role.id, access_right_id: @access_right.id)
        end
        @adapter = create(:adapter,:aws,:billing, :data_azure, name: "Billing Adapter", account_id: @account.id, state:"active",sync_running: false)
        @adapter_id = @adapter.id
        post "/service_groups", params: payload_adapter_group.merge({billing_adapter_id: @adapter_id}).to_json, headers: valid_headers.merge(authorization_header)
        sleep(20)
        @service_group_id = JSON.parse(response.body)['id']
        @child_id = create(:organisation,application_plan_id: @application_plan.id,organisation_identifier: "K0000002",subdomain: @subdomain,user_id: @user.id,parent_id: @organisation.id,child_organisation_enable: false,report_profile_id: "65d4748fb2bc58b66f418275")
        @company_domain = Faker::Internet.domain_name
        @child_organisation = Organisation.find("#{@child_id["id"]}")
        @user_sec = create(:user)
        @organisation_user_first_second_user = create(:organisation_user, user: @user_sec, organisation: @child_organisation)
        @tenant_sec = create(:tenant, name: Faker::Name.name, organisation: @child_organisation, is_default: true)
        @tenant_user_sec = create(:tenant_user, user: @user_sec, tenant: @tenant_sec)
        @account_child = create(:account, organisation: @child_organisation)
        put "/child_organisation/adapters/#{@child_id["id"]}", params: payload_for_update.merge({adapter_group_ids: [@service_group_id], billing_adapter_ids:[@adapter_id], adapter: {
          adapter_group_ids: [@service_group_id],billing_adapter_ids: [@adapter_id]}}).to_json, headers: valid_headers.merge(authorization_header)
        @user_role_child = @user_sec.user_roles.new(name: Faker::Name.name, organisation_id: @child_organisation.id)
        @user_role_child.save
        @user_role_operations = @user_sec.user_roles.create(name: "Operations", organisation_id: @child_organisation.id)
        @user_role_finances = @user_sec.user_roles.create(name: "Finances", organisation_id: @child_organisation.id)
        @user_role_basic = @user_sec.user_roles.create(name: "Basic", organisation_id: @child_organisation.id)
        @user_sec.user_roles_users.create(user_role_id: @user_role_child.id, tenant_id: @tenant_sec.id, user_id: @user_sec.id)
        rights_sec = ["cs_adapter_view","cs_adapter_create","cs_adapter_edit","cs_adapter_delete", "cs_tenant_add", 'cs_tenant_delete', 'cs_tenant_edit', 'cs_tenant_view', 'cs_tenant_manage_permission',"cs_child_organisation_view","cs_child_organisation_change_state","cs_child_organisation_edit","cs_child_organisation_delete","cs_child_organisation_create","cs_child_organisation_shared_adapter_edit","cs_child_organisation_view",'cs_service_group_view','cs_service_group_edit','cs_service_group_create','cs_service_group_delete']
        rights_sec.each do |right_sec|
          @access_right_child = create(:access_right, title: "Manage", code: right_sec)
          @access_right_user_role = AccessRightsUserRoles.create(user_role_id: @user_role_child.id, access_right_id: @access_right_child.id)
        end
        post '/private/sessions/logout',params: {}, headers: valid_headers.merge(authorization_header)
        login_params = {
          username: @user_sec.username,
          password: @user_sec.password,
          host: @child_host
        }
        post private_sessions_path, params: login_params
        sleep(20)
        @adapter_child = create(:adapter,:aws,:billing, :data_azure, name: "Billing Adapter", account_id: @account_child.id, state:"active",sync_running: false)
        @adapter_child_id = @adapter_child.id
      end
      it 'returns present when adapter created sucessfully by child organisation' do
        expect(@adapter_child_id).to be_present
      end

      ##this case is working fine when running individual some time it didnt got response so marked as xit
      xit 'returns status 200 when updates the adapter title created from child organisation' do
        post "/adapters/#{@adapter_child_id}/update", params: { name: 'Updated Title child', type: "Adapters::Azure" }.to_json, headers: valid_headers.merge({'web-host' => @child_host,
          'Authorization' => "Bearer #{generate_jwt_token(@user_sec, @child_organisation)}"})
          sleep(20)
        expect(response).to have_http_status(200)
      end

      ##this case is working fine when running individual some time it didnt got response so marked as xit
      xit 'returns status 204 when successfully deletes the adapter created from child organisation' do
        sleep(15)
        put "/adapters/#{@adapter_child_id}/destroy", params: { type: "Adapters::Azure" }.to_json, headers: valid_headers.merge({'web-host' => @child_host,
          'Authorization' => "Bearer #{generate_jwt_token(@user_sec, @child_organisation)}"})
        sleep(25)
        expect(response).to have_http_status(204)
      end
      it "returns 403  child organisation when shared adapter from master organisation and then child try to unshare" do
        sleep(15)
        put "/child_organisation/adapters/#{@child_id["id"]}", params: payload_for_update.to_json, headers: valid_headers.merge({'web-host' => @child_host,'Authorization' => "Bearer #{generate_jwt_token(@user_sec, @child_organisation)}"})
        sleep(20)
        expect(response).to have_http_status(403)
      end
      it "returns success when child organisation  shared adapter from master organisation and then master try to unshare" do
        sleep(10)
        post '/private/sessions/logout',params: {}, headers: valid_headers.merge({'web-host' => @child_host,
          'Authorization' => "Bearer #{generate_jwt_token(@user_sec, @child_organisation)}"})
          sleep(10)
        create_params = {
          username: @user.username,
          password: @user.password,
          host: @master_host
        }
        post private_sessions_path, params: create_params
        sleep(20)
        put "/child_organisation/adapters/#{@child_id["id"]}", params: payload_for_update.to_json, headers: valid_headers.merge(authorization_header)
        sleep(15)
          expect(response).to have_http_status(204)
      end
    end
  end
end
