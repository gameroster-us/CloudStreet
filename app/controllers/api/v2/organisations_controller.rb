class Api::V2::OrganisationsController < Api::V2::SwaggerBaseController
  before_action :find_current_organisation

  # def index
  #   ChildOrganisation::Organisation::Fetcher.list_all(current_organisation, params) do |result|
  #     result.on_success { |organisations| respond_with_user_and organisations[0], total_records: organisations[1], represent_with: OrganisationsRepresenter }
  #     result.on_error { |message| render json: { message: message }, status: 500 }
  #   end
  # end

  # def show
  #   ChildOrganisation::Organisation::Fetcher.find(current_organisation) do |result|
  #     result.on_success { |organisation| respond_with_user_and organisation, represent_with: OrganisationRepresenter }
  #     result.on_error   { render body: nil, status: 500 }
  #   end
  # end

  def users
    ChildOrganisation::Organisation::Fetcher.organisation_users_list(params) do |result|
      result.on_success { |org_users| respond_with_user_and org_users[0], total_records: org_users[1], represent_with: ChildOrganisation::OrgUsersRepresenter }
      result.on_error { |message| render json: { message: message }, status: 500 }
    end
  end

  # def users
  #   UserSearcher.search_organisation_users(orgnisation, current_tenant, user_params) do |result|
  #     result.on_success { |users| respond_with_user_and users[0], total_records: users[1], represent_with: UsersRepresenter }
  #     result.on_error   { render body: nil, status: 500 }
  #   end
  # end

  # private

  # def user_params
  #   params.permit(:page_size, :page_number, :query, :state, :roles)
  # end
end
