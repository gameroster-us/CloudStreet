class Reportapi::Api::V1::BudgetsController < ApplicationController

  def index
    render json: {}
  end

  def create
    render json: {}
  end

  def update
    render json: {}
  end

  def show
    render json: {}
  end

  def destroy
    render json: {}
  end

  private

  def budget_params
    params.require(:budget).permit!
  end
end
