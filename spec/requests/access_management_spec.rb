require 'rails_helper'

RSpec.describe 'Access Management:', type: :request do
  
  before(:each, :webmock_enabled) do
    WebMock.enable!
  end

  before(:all) do
    create_session_for_billing_adapter(Adapters::AWS)
  end

  let(:authorization_token) { Settings.authorization_token }

  let(:cloudstreet_notification_url) { Settings.authorization_token }

  let(:valid_credentials) do
    {
      email: Faker::Internet.email,
      tenant_ids: [
        @organisation.tenants.first.id
      ],
      role_ids: [
        @user_role.id
      ]
    }
  end

  def role_params(name, role_id)
    {
      name: name,
      sso_keywords: [],
      provision_right: false,
      rights_ids: nil,
      role_id: role_id
    }
  end
  
  let(:create_role_params) do 
    {
      name: 'test_role',
      sso_keywords: "",
      provision_right: false,
      rights_ids: nil
    }
  end
  
  let(:admin_role_params) { role_params("Administrator", @user_role.id) }
  let(:operation_role_params) { role_params("Operations", @user_role_operations.id) }
  let(:finance_role_params) { role_params("Finances", @user_role_finances.id) }
  let(:basic_role_params) { role_params("Basic", @user_role_basic.id) }

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
  let(:valid_enable_disable_params) do 
    {
      enabled_user_ids: nil,
      disabled_user_ids: nil
    }
  end 

  let(:password) {Settings.password}

  let(:log_in_params) do 
    {
      email: nil,
      password: password
    }
  end

  context 'invite user' do 
    before do 
      stub_request(:any, /https:\/\/track\.customer\.io\/api\/v1\/customers\/[0-9a-f-]+(?:\/events)?/)
      .with(
        headers: {
          'Authorization' => authorization_token,
          'Content-Type' => 'application/json',
          'User-Agent' => 'Customer.io Ruby Client/5.3.0'
        }
      ) do |request|
        request_body = JSON.parse(request.body)
      end 
      .to_return(status: 200, body: "{\"success\": true, \"message\": \"Request processed successfully\"}", headers: {})
      post invite_organisations_path, params: valid_credentials.to_json, headers: valid_headers.merge(authorization_header)
      @invited_user = User.find_by_unconfirmed_email(valid_credentials[:email] )
      @user_preference = UserPreference.find_by_prefereable_id(@invited_user.id)
      @invited_organisation_user = OrganisationUser.find_by_user_id(@invited_user.id)
    end
    
    context 'test invite user response' do
                         
      it_behaves_like 'test status code 200'

      it 'should responds with success message' do 
        expect(JSON.parse(response.body)).to include("message" => "Invitation has been sent to entered Email Id")
      end 
      
      it 'it should call mailer service', :webmock_enabled do
        expect(WebMock).to have_requested(:any, /https:\/\/track\.customer\.io\/api\/v1\/customers\/[0-9a-f-]+(?:\/events)?/).at_least_once
      end

      it 'should return user state as invited' do
        expect(@invited_user.state).to eq('invited')
      end

      it 'should return user preference sync guidelines as true' do
        expect(@user_preference.preferences['sync_guidelines']).to eq(true)
      end
    end

    context 'invite user with invalid params' do 

      before do 
        post invite_organisations_path, params: valid_credentials.merge(role_ids: nil).to_json, headers: valid_headers.merge(authorization_header)
      end 

      it_behaves_like 'test status code 422'

      it 'should responds with success message' do 
        expect(JSON.parse(response.body)["validation_errors"]).to include(["role_ids", "cannot be blank"]
        )
      end 
    end

    context 'disable invited user' do 
      before do 
        @activate_invited_user = create(:active_invited_user, account: @account)
        post enable_disable_member_users_path, params: valid_enable_disable_params.merge(disabled_user_ids: @activate_invited_user.id ).to_json, headers: valid_headers.merge(authorization_header)
      end

      it_behaves_like 'test status code 200'

      it 'should responds with success message' do 
        expect(JSON.parse(response.body)).to include("success" => true)
      end 

      it 'should return user preference sync guidelines as true' do
        expect(OrganisationUser.find_by_user_id(@activate_invited_user.id).state).to eq('disabled')
      end
      
      context 'enable invited user' do 
        before do 
          post enable_disable_member_users_path, params: valid_enable_disable_params.merge(enabled_user_ids: @activate_invited_user.id ).to_json, headers: valid_headers.merge(authorization_header)
        end
  
        it_behaves_like 'test status code 200'
  
        it 'should responds with success message' do 
          expect(JSON.parse(response.body)).to include("success" => true)
        end 
  
        it 'should return user preference sync guidelines as true' do
          expect(OrganisationUser.find_by_user_id(@activate_invited_user.id).state).to eq('active')
        end 
      end
    end

    context 'delete user' do 
      before do 
        delete delete_invited_user_organisation_path(@invited_user), headers: valid_headers.merge(authorization_header)
      end
      it_behaves_like 'test status code 200' 

      it 'should responds with success message' do 
        expect(JSON.parse(response.body)).to include("success" => "User is removed from Organisation")
      end 
    end 

    context 'invite deleted user' do 
      before do 
        delete delete_invited_user_organisation_path(@invited_user), headers: valid_headers.merge(authorization_header)
        post invite_organisations_path, params: valid_credentials.to_json, headers: valid_headers.merge(authorization_header)
      end

      it_behaves_like 'test status code 200'

      it 'should responds with success message' do 
        expect(JSON.parse(response.body)).to include("message" => "Invitation has been sent to entered Email Id")
      end
    end 

    context 'resent invite' do 
      before do 
        post invite_organisations_path, params: valid_credentials.to_json, headers: valid_headers.merge(authorization_header)
      end

      it_behaves_like 'test status code 409'
      
      it 'responds with error message' do 
        expect(JSON.parse(response.body)['error_desc']).to include("User has already been invited to your organisation.")
      end 
    end 

    context 'edit admin user role permission' do 

      before do 
        @admin_user_role = @user.user_roles
        @right_ids = AccessRightsUserRoles.where(user_role_id: @admin_user_role).pluck(:access_right_id)
        allow(AlertService).to receive(:set_alert).and_return(true)
        put "/user_roles/#{@user_role.id}", params: admin_role_params.merge(rights_ids: @right_ids ).to_json, headers: valid_headers.merge(authorization_header)
      end
      
      it_behaves_like 'test status code 200'

      it 'sent notification with alert service' do
        expect(AlertService).to have_received(:set_alert).at_least(:once)
      end

      it 'should have to same rights as assigned' do 
        expect(AccessRightsUserRoles.where(user_role_id: @admin_user_role).pluck(:access_right_id)).to include(*@right_ids)
      end
    end

    context 'edit finance user role permission' do 
     
      before do
        @finance_user_role = @user.user_roles
        @right_ids = AccessRightsUserRoles.where(user_role_id: @finance_user_role).pluck(:access_right_id)
        allow(AlertService).to receive(:set_alert).and_return(true)
        put "/user_roles/#{@user_role_finances.id}", params: finance_role_params.merge(rights_ids: @right_ids ).to_json, headers: valid_headers.merge(authorization_header)
      end 

      it_behaves_like 'test status code 200'

      it 'sent notification with alert service' do
        expect(AlertService).to have_received(:set_alert).at_least(:once)
      end

      it 'should have to same rights as assigned' do
        expect(AccessRightsUserRoles.where(user_role_id: @finance_user_role).pluck(:access_right_id)).to include(*@right_ids)
      end
    end 

    context 'edit basic user role permission' do 
     
      before do
        @basic_user_role = @user.user_roles
        @right_ids = AccessRightsUserRoles.where(user_role_id: @basic_user_role).pluck(:access_right_id)
        allow(AlertService).to receive(:set_alert).and_return(true)
        put "/user_roles/#{@user_role_basic.id}", params: basic_role_params.merge(rights_ids: @right_ids ).to_json, headers: valid_headers.merge(authorization_header)
      end

      it_behaves_like 'test status code 200'

      it 'sent notification with alert service' do
        expect(AlertService).to have_received(:set_alert).at_least(:once)
      end

      it 'should have to same rights as assigned' do 
        expect(AccessRightsUserRoles.where(user_role_id: @basic_user_role).pluck(:access_right_id)).to include(*@right_ids)
      end
    end

    context 'edit operation user role permission' do 
      
      before do
        @operation_user_role = @user.user_roles
        @right_ids = AccessRightsUserRoles.where(user_role_id: @operation_user_role).pluck(:access_right_id)
        stub_request(:post, cloudstreet_notification_url).
          with(
            body: {"additional_data"=>"{}", "alert_type"=>"info", "alertable_id"=>"#{@user.id}", "alertable_type"=>"User", "code"=>"update_access_permission"},
            headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Type'=>'application/x-www-form-urlencoded',
            'User-Agent'=>'Ruby'
            }).
        to_return(status: 200, body: "", headers: {})

        put "/user_roles/#{@user_role_operations.id}", params: operation_role_params.merge(rights_ids: @right_ids ).to_json, headers: valid_headers.merge(authorization_header)
      end

      it_behaves_like 'test status code 200'

      it 'should have to same rights as assigned' do 
        expect(AccessRightsUserRoles.where(user_role_id: @operation_user_role).pluck(:access_right_id)).to include(*@right_ids)
      end
    end

    context 'manage role' do

      before do 
        user_role = @user.user_roles
        @right_ids = AccessRightsUserRoles.where(user_role_id: user_role).pluck(:access_right_id)
        post user_roles_path, params: create_role_params.merge(rights_ids: @right_ids ).to_json, headers: valid_headers.merge(authorization_header)
      end 
  
      context 'add role with provision right' do 
        it_behaves_like 'test status code 201' 
      end
  
      context 'adding existing role' do 
        before do 
          post user_roles_path, params: create_role_params.merge(rights_ids: @right_ids ).to_json, headers: valid_headers.merge(authorization_header)
        end
  
        it_behaves_like 'test status code 422'
  
        it 'should responds with error message' do 
          expect(JSON.parse(response.body)['validation_errors']).to include(["name", ["has already been taken"]])
        end 
      end 
  
      context 'delete role' do 
      
        before do 
          @role = UserRole.find(JSON.parse(response.body)['id'])
          delete "/user_roles/#{@role.id}", headers: valid_headers.merge(authorization_header)
        end 
  
        it_behaves_like 'test status code 204'
      end 
      
      context 'delete role with member' do 
        before do 
          delete "/user_roles/#{@user_role.id}", headers: valid_headers.merge(authorization_header)     
        end
  
        it_behaves_like 'test status code 422'
  
        it 'should responds with error message' do 
          expect(JSON.parse(response.body)).to include("validation_error" => {"message"=>"Role can't be deleted, members are associated with role."})
        end 
      end
    end 
  end  

  context 'test operation user righs' do 
    before do 
      setup_user_session
    end
  
    context 'without delete role right' do 
      before do 
        setup_and_destroy_access_right('cs_access_role_delete')
        role = UserRole.find(JSON.parse(response.body)['id'])
        delete_user_role(role)
      end   
      
      it_behaves_like 'test status code 403'

      it_behaves_like 'validate not authorized message'
    end
  
    context 'without add role right' do 
      before do 
        setup_and_destroy_access_right('cs_access_role_add')
        create_user_role
      end   
      
      it_behaves_like 'test status code 403'

      it_behaves_like 'validate not authorized message'
    end
  
    context 'without edit role right' do 
      before do 
        setup_and_destroy_access_right('cs_access_role_edit')
        create_user_role
        update_user_role
      end   
      
      it_behaves_like 'test status code 403'

      it_behaves_like 'validate not authorized message'
    end
  
    context 'without view and manage user rights' do 
      before do 
        create_user_role
        view_user_roles
      end   
      
      it_behaves_like 'test status code 403'

      it_behaves_like 'validate not authorized message'
    end
  end

  context do 
    before do 
      post logout_private_sessions_path , params: {} , headers: valid_headers.merge(authorization_header)
      expect(response).to have_http_status(200)
      post invite_organisations_path, params: valid_credentials.to_json, headers: valid_headers.merge(authorization_header)
    end 
    it_behaves_like 'test status code 401' 
    it_behaves_like 'validate 401 not authorized message' 
  end    

  after(:each) do
    WebMock.allow_net_connect!
  end
end