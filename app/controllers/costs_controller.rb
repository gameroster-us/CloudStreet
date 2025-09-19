class CostsController < ApplicationController
  def index
    Costs::Searcher.new(current_account, params).search do |result|
      result.on_success { |response| render json: response, status: 200 }
      result.on_error   { |error_msg| render json: { error_msg: error_msg }, status: 400 }
    end
  end

  def cost_by_service
    Costs::Searcher.new(current_account, params).cost_by_service do |result|
      result.on_success { |response| render json: response, status: 200 }
      result.on_error   { |error_msg| render json: { error_msg: error_msg }, status: 400 }
    end
  end
end
