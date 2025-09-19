class SecurityGroupsController < ApplicationController
  before_action :find_and_authorize, except: [:create]
  authority_actions authorize_port_range_inbound: 'update', revoke_port_range_inbound: 'update', authorize_port_range_outbound: 'update', revoke_port_range_outbound: 'update', delete_security_group: 'delete'

  # Commenting instance level authorisation checks
  def show
    SecurityGroups::Searcher.find(@security_group) do |result|
      result.on_success { |sg| respond_with_user_and sg, represent_with: SecurityGroups::SecurityGroupRepresenter }
    end
  end
  
  ["inbound", "outbound"].each do |protocol|
    define_method("authorize_port_range_#{protocol}") do
      SecurityGroups::Rules.send("add_#{protocol}", @security_group, add_rule_params[:rule]) do |result|
        result.on_success          { |sg| force_render_json_with_user_of sg, represent_with: SecurityGroups::SecurityGroupRepresenter }
        result.on_fog_error        { |error_msg| render status: 409, json: { error: error_msg.gsub(/\\/, '') } }
        result.on_error            { render body: nil, status: 500 }
        result.on_validation_error { |error_msgs| render status: 400, json: { validation_error: error_msgs } }
      end
    end

    define_method("revoke_port_range_#{protocol}") do
      SecurityGroups::Rules.send("remove_#{protocol}", @security_group, add_rule_params[:rule]) do |result|
        result.on_success   { |sg| force_render_json_with_user_of sg, represent_with: SecurityGroups::SecurityGroupRepresenter }
        result.on_fog_error { |error_msg| render status: 409, json: { error: error_msg } }
        result.on_error     { render body: nil, status: 500 }
      end
    end
  end

  def create
    SecurityGroups::Rules.create_security_group(create_params, current_organisation, user, params) do |result|
      result.on_success { |security_group| respond_with_user_and security_group, represent_with: SecurityGroups::SecurityGroupRepresenter, location: security_groups_url }
      result.on_validation_error { |error_msgs| render status: 422, json: { validation_error: error_msgs } }
      result.on_fog_error { |error_msg| render status: 409, json: { error: error_msg } }
      result.on_error     { render body: nil, status: 500 }
    end    
  end

  def delete_security_group
    SecurityGroups::Rules.delete_security_group(current_account, user, sg_id_params) do |result|
      result.on_success { |security_group| respond_with_user_and security_group, status: 204, represent_with: SecurityGroups::SecurityGroupRepresenter }
      result.on_validation_error { |error_msgs| render status: 400, json: { validation_error: error_msgs } }
      result.on_fog_error { |error_msg| render status: 409, json: { error: error_msg } }
      result.on_error     { render body: nil, status: 500 }
    end
  end

  # def update_name
  #   SecurityGroups::Updater.update_name(@security_group, update_name_params, user) do |result|
  #     result.on_success { |sg| respond_with_user_and sg }
  #     result.on_validation_error { |sg| render status: 422, json: cloudstreet_error(:validation_error, sg.errors.messages) }
  #     result.on_error  { render body: nil, status: 500 }
  #   end
  # end

  private

  def find_and_authorize
    @security_group = SecurityGroup.find params[:id]
    #authorize_action_for @security_group
  end

  def sg_id_params
    params.permit(:id)
  end
  def create_params
   params.permit(:name, :description, :vpc_id, :name_free_text).tap do |white_listed|
      white_listed[:account_tags] = params[:account_tags]
    end
  end

  def update_name_params
    params.permit(:name)
  end

  def add_rule_params
    params.permit(rule: {})
  end
end
