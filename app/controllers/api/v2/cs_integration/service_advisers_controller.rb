# frozen_string_literal: true

class Api::V2::CSIntegration::ServiceAdvisersController < Api::V2::ApiBaseController
  require 'csv'
  BOOLEAN_ARRAY = { 'false' => false, 'true' => true }.freeze

  def cost_efficiency_summary
    CSIntegration::ServiceAdviser::Base.cost_efficiency_summary(user, current_tenant, adapter_filter) do |result|
      result.on_success { |response| respond_with response, represent_with: ServiceAdviser::AWS::CostEfficiencySummaryRepresenter }
      result.on_error { |e| render json: { error_message: e.message }, status: 422 }
    end
  end

  def list_service_type_with_count
    return render json: { message: 'Normal Adapter is not available in CloudStreet' }, status: 422 if common_filters[:adapter_id].blank?

    "CSIntegration::#{params[:service_adviser_klass]}".constantize.list_service_type_with_count(common_filters, current_account, current_tenant, user) do |result|
      result.on_success do |services|
        respond_to do |format|
          format.any { render json: services.to_json, status: :ok }
        end
      end
      result.on_error do |e|
        CSLogger.error("#{e.class} : #{e.message}")
        CSLogger.error(e.backtrace)
        render json: { error_message: e.message }, status: 422
      end
    end
  end

  def list_service_type_with_detail
    paginate = { page: params[:page].to_i, per_page: params[:per_page].to_i }
    sort_by = params['sort_by'].blank? && params['sort'].blank? ? nil : params['sort_by'] + ' ' + params['sort']
    "CSIntegration::#{params[:service_adviser_klass]}".constantize.list_service_type_with_detail(common_filters, paginate, sort_by, current_account, current_tenant, user) do |result|
      result.on_success { |response| respond_with_user_and response, represent_with: params[:service_adviser_klass].constantize::ListServiceTypeWithDetailRepresenter }
      result.on_error do |e|
        CSLogger.error("#{e.class} : #{e.message}")
        CSLogger.error(e.backtrace)
        render json: { error_message: e.message }, status: 422
      end
    end
  end

  def show_ignored_services
    adapter_id = get_adapter
    return render json: { message: 'Normal Adapter is not available in CloudStreet' }, status: 422 if adapter_id.blank?

    params[:adapter_ids] = adapter_id
    CSIntegration::ServiceAdviser::AWS.show_ignored_services_cs(current_account, current_tenant, params) do |result|
      result.on_success do |response|
        respond_to do |format|
          format.any { render json: response.to_json, status: :ok }
        end
      end
      result.on_error { |e| render json: { error_message: e.message }, status: 422 }
    end
  end

  def get_recommendation_csv
    adapter_id = get_adapter
    tags = begin
      JSON.parse(params['tags'])
           rescue StandardError
             []
    end
    filters = { adapter_id: adapter_id, region_id: params[:region_id], service_type: params[:service_type], environment_id: params[:environment_id], public_snapshot: params[:public_snapshot], tags: tags, lifecycle: (begin
      params[:lifecycle].downcase
                                                                                                                                                                                                                        rescue StandardError
                                                                                                                                                                                                                          []
    end), cpu_utilization: params[:cpu_utilization], memory_utilization: params[:memory_utilization], adapter_group_id: params[:adapter_group_id] }
    paginate = {}
    sort_by = params['sort_by'].blank? && params['sort'].blank? ? nil : params['sort_by'] + ' ' + params['sort']
    result = "CSIntegration::#{params[:service_adviser_klass]}".constantize.list_service_type_with_detail(filters, paginate, sort_by, current_account, current_tenant, user)
    result = result.extend(params[:service_adviser_klass].constantize::ListServiceTypeWithDetailRepresenter)
    result = JSON.parse(result.to_json, object_class: OpenStruct)
    result = "CSIntegration::#{params[:service_adviser_klass]}".constantize.recommended_csv(result, params[:service_type], current_account)
    send_data result, type: 'text/csv', filename: 'recommendation.csv'
  end

  def get_key_values_array
    adapter_id = get_adapter
    return render json: { message: 'Normal Adapter is not available in CloudStreet' }, status: 422 if adapter_id.blank?

    filters = { adapter_id: [adapter_id], lifecycle: params[:lifecycle] }
    filters.merge!({ region_id: params[:region_id] }) if params[:region_id]
    "CSIntegration::#{params[:service_adviser_klass]}".constantize.get_key_values_array(filters, current_tenant) do |result|
      result.on_success do |response|
        respond_to do |format|
          format.any { render json: response.to_json, status: :ok }
        end
      end
      result.on_error { |e| render json: { error_message: e.message }, status: 422 }
    end
  end

  def get_right_sized_instances
    adapter_id = get_adapter
    return render json: { message: 'Normal Adapter is not available in CloudStreet' }, status: 422 if adapter_id.blank?

    params[:adapter_id] = adapter_id
    authorize_action_with_condition(:get_right_sized_instances, ServiceAdviserAuthorizer)
    ::CSIntegration::AWS::RightSizingService.get_right_sized_instances(params, current_account, current_tenant) do |result|
      result.on_success { |response| respond_with response[0], user_options: { current_user: @user, current_account: current_account, current_tenant: current_tenant }, total_records: response[1], represent_with: ServiceAdviser::AWS::EC2RightsizingInstancesSummaryRepresenter, status: 200 }
      result.on_error { |e| render json: { error_message: e.message }, status: 422 }
    end
  end

  #right_sizing csv
  def get_formatted_csv
    adapter_id = get_adapter
    return render json: { message: 'Normal Adapter is not available in CloudStreet' }, status: 422 if adapter_id.blank?

    params[:adapter_id] = adapter_id
    result = ::CSIntegration::AWS::RightSizingService.get_right_sized_instances(params, current_account, current_tenant)
    response = CSIntegration::AWS::RightSizingService.to_csv(result)
    send_data response, type: 'text/csv'
  end

  private

  def common_filters
    adapter_id = get_adapter
    tags = begin
      JSON.parse(params['tags'])
           rescue StandardError
             []
           end
    {
      adapter_id: adapter_id, region_id: params[:region_id],
      service_type: params[:service_type], environment_id: params[:environment_id],
      public_snapshot: params[:public_snapshot], tags: tags, lifecycle: params[:lifecycle],
      cpu_utilization: params[:cpu_utilization], memory_utilization: params[:memory_utilization],
      adapter_group_id: params[:adapter_group_id], vcenter_id: params[:vcenter_id],
      tag_operator: params[:tag_operator].blank? ? 'OR' : params[:tag_operator]
    }
  end

  def get_adapter
    klass = params[:service_adviser_klass].split('::').last
    case klass
    when 'AWS'
      ::Adapters::AWS.normal_adapters.available.where(account_id: current_account.id)
                     .where("data-> 'aws_account_id'=?", params[:adapter_id]).first.try(:id)
    when 'Azure'
      ::Adapters::Azure.normal_adapters.available.where(account_id: current_account.id)
                       .where("data-> 'subscription_id'=?", params[:adapter_id]).first.try(:id)
    when 'GCP'
      ::Adapters::GCP.normal_adapters.available.where(account_id: current_account.id)
                       .where("data-> 'project_id'=?", params[:adapter_id]).first.try(:id)
    end
  end

  def adapter_filter
    adapter_id = get_adapter
    { adapter_id: adapter_id }
  end
end
