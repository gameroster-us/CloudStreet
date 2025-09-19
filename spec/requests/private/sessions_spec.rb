require 'rails_helper'

RSpec.describe "Private::Sessions", type: :request do
  include FactoryBot::Syntax::Methods

  let(:invalid_host) { 'http://invalidhost.cloudstreet.local:8080' }
  let(:invalid_username) { Faker::Internet.username }
  let(:invalid_password) { Faker::Internet.password }

  before(:all) do
    @user = create(:user)
    @organisation = create(:organisation, :with_viewer_plan, user_id: @user.id)
    @organisation_user = create(:organisation_user, user: @user, organisation: @organisation)
    @tenant = create(:tenant, organisation: @organisation)
    @tenant_user = create(:tenant_user, user: @user, tenant: @tenant)
    @account = create(:account, organisation: @organisation)
  end

  let(:valid_host) { "http://#{@organisation.subdomain}.#{Settings.env_host }" }

  let(:create_params) do
    {
      username: @user.username,
      password: @user.password
    }
  end

  describe 'POST /private_sessions' do
    context 'when username, password, and subdomain are valid' do
      
      before do
        create_params[:host] = valid_host
        post private_sessions_path, params: create_params
      end

      it_behaves_like 'test status code 201'

      it 'response have username' do
        expect(JSON.parse(response.body)).to include('name' => @user.name)
      end

      it 'response have email' do
        expect(JSON.parse(response.body)).to include('email' => @user.email)
      end
    end

    context 'when username and password are valid but subdomain does not exist' do

      before do
        post private_sessions_path, params: create_params
      end
      
      it_behaves_like 'test status code 422'

      it 'responds with unavailable organisation' do
        expect(JSON.parse(response.body)).to include('message' => 'Organisation is unavailable. please contact administrator.')
      end   
    end

    context 'when username and password are valid but subdomain is invalid' do
    
      before do 
        create_params[:host] = invalid_host
        post private_sessions_path, params: create_params
      end

      it_behaves_like 'test status code 422'   
      
      it 'responds with unavailable organisation' do
        expect(JSON.parse(response.body)).to include('message' => 'Organisation is unavailable. please contact administrator.')
      end
    end

    context 'when user does not exist' do

      before do
        create_params[:username] = invalid_username
        create_params[:password] = invalid_password
        create_params[:host] = valid_host
        post private_sessions_path, params: create_params
      end

      it_behaves_like 'test status code 422'

      it 'response have error message' do
        expect(JSON.parse(response.body)).to include('message' => 'Incorrect username or password.')
      end
    end

    context 'when logging in to a valid subdomain and invited to another subdomain' do 

      before do 
        create_params[:host] = valid_host
        post private_sessions_path, params: create_params
      end

      it_behaves_like 'test status code 201'

      it 'response have username' do
        expect(JSON.parse(response.body)).to include('name' => @user.name)
      end

      it 'response have email' do
        expect(JSON.parse(response.body)).to include('email' => @user.email)
      end
    end
  end
end