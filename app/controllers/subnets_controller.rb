class SubnetsController < ApplicationController

  before_action :find_and_authorize, except: [:create_subnet]
  authority_actions create_subnet: 'update', delete_subnet: 'update', edit_subnet: 'update'

  # Commenting instance level authorisation checks
  def show
    #authorize_action_for @subnet

    RouteTables::Searcher.find(@subnet) do |result|
      result.on_success { |subnet| respond_with_user_and subnet, represent_with: Subnets::SubnetRepresenter }
    end
  end

  def create_subnet
    Subnets::Rules.create_subnet(params, user) do |result|
      result.on_success { |subnet| force_render_json_with_user_of subnet, represent_with: Subnets::SubnetRepresenter }
      result.on_validation_error { |error_msgs| render status: 400, json: { validation_error: error_msgs } }
      result.on_fog_error { |error_msg| render status: 409, json: { error: error_msg } }
      result.on_error     { render body: nil, status: 500 }
    end
  end
  
  def edit_subnet
    Subnets::Rules.edit_subnet(@subnet,params[:name]) do |result|
       result.on_success { |subnet| force_render_json_with_user_of subnet, represent_with: Subnets::SubnetRepresenter }
       result.on_validation_error { |error_msgs| render status: 400, json: { validation_error: error_msgs } }
       result.on_fog_error { |error_msg| render status: 409, json: { error: error_msg } }
       result.on_error     { render body: nil, status: 500 }
     end 
  end

  def delete_subnet
    Subnets::Rules.delete_subnet(@subnet, params[:route]) do |result|
      result.on_success { |subnet| force_render_json_with_user_of subnet, represent_with: Subnets::SubnetRepresenter }
      result.on_fog_error { |error_msg| render status: 409, json: { error: error_msg } }
      result.on_error     { render body: nil, status: 500 }
    end
  end

  def find_and_authorize
    @subnet = Subnet.find params[:id]
    #authorize_action_for @subnet
  end

end
