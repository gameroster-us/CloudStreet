class Api::V2::AWSController < Api::V2::SwaggerBaseController
  def get_cost_usage_reports
    if params[:role_based]
      return render json: { message: "Please Enter Valid AWS Account ID." }, status: 422 unless params[:aws_account_id].to_i.to_s.eql?(params[:aws_account_id]) &&  params[:aws_account_id].to_i.to_s.length.eql?(12) && params[:aws_account_id].present?

      return render json: { message: "Please Enter Valid Role arn." }, status: 422 unless params[:role_arn].present? && params[:role_arn]&.tr("^0-9","").to_i.to_s.length.eql?(12)
    end

    params[:type] = 'Adapters::AWS'
    params[:default_config] = true
    AdapterCreator.get_report_names(params, current_account) do |result|
      result.on_success { |adapter| render json: { result: result.resources } }
      result.on_error   { render body: nil, status: 500, json: { validation_error: result.resources } }
    end
  end
end