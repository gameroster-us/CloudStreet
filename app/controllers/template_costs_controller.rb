class TemplateCostsController < ApplicationController
  def index
    TemplateCostService.search(current_account, template_cost_params) do |result|
      result.on_success { |costings| respond_with_user_and costings, represent_with: TemplateCostsRepresenter  }
      result.on_error   { |message| render status: 400, json: { validation_error: message } }
    end
  end

  private

  def template_cost_params
    params.permit(:region_id, :data, :type, :created_at, :updated_at)
  end
end
