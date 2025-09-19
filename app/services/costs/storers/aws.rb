class Costs::Storers::AWS < Costs::Storer
  attr_accessor :csv_heading_line, :index_of_environment_tag, :index_of_un_blended_cost, :index_of_unblended_cost, :index_of_blended_cost, :index_of_product_name, :index_of_resource_id, :index_of_usage_end_date, :index_of_usage_start_date, :index_of_az

  START_DATE_FORMAT = '%Y-%m-%d %H:%M:%S'
  END_DATE_FROMAT = '%Y-%m-%d %H:%M:%S'

  EC2_PRODUCT_NAME = 'Amazon Elastic Compute Cloud'
  RDS_PRODUCT_NAME = 'Amazon RDS Service'

  def initialize(adapter, parsed_data, options={})
    super
    @csv_heading_line = parsed_data.first
    @index_of_az               = csv_heading_line.index 'AvailabilityZone'
    @index_of_environment_tag  = csv_heading_line.index 'user:environment'
    @index_of_unblended_cost   = csv_heading_line.index 'UnBlendedCost'
    @index_of_blended_cost     = csv_heading_line.index 'BlendedCost'
    @index_of_product_name     = csv_heading_line.index 'ProductName'
    @index_of_resource_id      = csv_heading_line.index 'ResourceId'
    @index_of_usage_end_date   = csv_heading_line.index 'UsageEndDate'
    @index_of_usage_start_date = csv_heading_line.index 'UsageStartDate'
  end

  def store
    attributes_map = parsed_data.inject({}) do |cost_map, row|
      row_product_name = row[index_of_product_name]
      # empty product_name in row indicates last four lines which contains sum of monthly cost
      # and if 'ProductName' is the value in row then it is the first line(csv_heading_line)
      next(cost_map) if row_product_name.blank? || row_product_name == 'ProductName'

      row_blended_cost = safely_convert_to_float(row[index_of_blended_cost], row)
      row_unblended_cost = safely_convert_to_float(row[index_of_unblended_cost], row)
      row_resource_id = row[index_of_resource_id]
      row_start_date = row[index_of_usage_start_date]
      row_end_date = row[index_of_usage_end_date]
      date = find_date(row_start_date, row_end_date)

      cost_map_key = [row_resource_id, date]
      cost_map[cost_map_key] ||= {}
      cost_attributes_map = cost_map[cost_map_key]

      if cost_attributes_map.present?
        cost_attributes_map[:blended_cost] += row_blended_cost
        cost_attributes_map[:unblended_cost] += row_unblended_cost
      else
        local_service = find_service(row_resource_id, row_product_name, row)
        cost_attributes_map.merge!({
          blended_cost: row_blended_cost,
          unblended_cost: row_unblended_cost,
          resource_id: row_resource_id,
          resource_type: row_product_name,
          date: date,
          type: ::Costs::AWS.to_s,
          availability_zone: row[index_of_az],
          adapter_id: local_service.try(:adapter_id) || adapter_id,
          account_id: local_service.try(:account_id) || account_id,
          environment_id: local_service.try(:environment).try(:id),
          service_id: local_service.try(:id)
        })
      end

      cost_map
    end

    costs_arr = add_entries_in_cost_table attributes_map.values # TO DO log_errors costs_arr
    cost_summaries_arr = add_entries_in_cost_summaries_table

    [costs_arr, cost_summaries_arr]
  end

  private

  def add_entries_in_cost_table(attributes_map)
    attributes_map.map do |cost_attr|
      # save in cost table
      cost = ::Costs::AWS.create cost_attr
      if cost.errors.any? # if there is a validation error means the record already exist in database ...
        cost = Cost.where(resource_id: cost_attr[:resource_id], adapter_id: cost_attr[:adapter_id], date: cost_attr[:date]).first # so find it ...
        result = cost.update(cost_attr) if cost.present? # already exist so just update it.
      end
      cost
    end
  end

  def add_entries_in_cost_summaries_table
    account = Account.find account_id
    account.organisation.adapters.each do |adapter|
      adapter_n_account_attr_map = { adapter_id: adapter.id, account_id: account_id }
      date_at_beginning_of_month  = date.at_beginning_of_month

      filtered_cost = ::Costs::AWS.where(adapter_n_account_attr_map)
      filtered_cost.environment_id_present.in_month(date).group(:environment_id).sum(:blended_cost).map do |environment_id, sum_of_blended_cost|
        cost_summary = ::CostSummaries::AWS.find_or_initialize_by(adapter_n_account_attr_map.merge(environment_id: environment_id, date: date_at_beginning_of_month))
        cost_summary.blended_cost = sum_of_blended_cost
        failed_to_save_cost_summary(cost_summary) unless cost_summary.save
        cost_summary
      end
    end
  end

  def find_service(resource_id, product_name, row)
    return if resource_id.blank?
    case product_name
    when EC2_PRODUCT_NAME
      find_ec2(resource_id, row)
    when RDS_PRODUCT_NAME
      find_rds(resource_id)
    else
      nil
    end
  end

  def find_ec2(resource_id, row)
    adapter = ::Adapter.find adapter_id
    if resource_id =~ /elasticloadbalancing/   # if it is load balancer
      extracted_resource_id = resource_id.split('/')[-1]
      extracted_region_code = resource_id.split(':')[3]
      # TO DO Optimize to not query the db
      # Can be done by querying all region before the loop and prepare a hash for it.
      region = Region.where(adapter_id: Adapters::AWS.provider_adapter, code: extracted_region_code).first
      return if region.nil?
      region_id = region.id
      Service.where(provider_id: extracted_resource_id, region_id: region_id, account_id: adapter.account_id).first
    else # it is 'volume' or 'ec2-instance' or 'EIP'
      Service.where(provider_id: resource_id, account_id: adapter.account_id).first
    end
  end

  def find_rds(resource_id)
    adapter = ::Adapter.find adapter_id
    splitted_resource_id = resource_id.split(':')
    extracted_resource_id = splitted_resource_id[-1]
    extracted_region_code = splitted_resource_id[3]
    # TO DO Optimize to not query the db
    # Can be done by querying all region before the loop and prepare a hash for it.
    region = Region.where(adapter_id: Adapters::AWS.provider_adapter, code: extracted_region_code).first
    return if region.nil?
    region_id = region.id
    Service.where(provider_id: extracted_resource_id, region_id: region_id, account_id: adapter.account_id).first
  end

  def find_date(start_date, end_date)
    parsed_start_date = parse_date(start_date, START_DATE_FORMAT)
    # parsed_end_date = parse_date(end_date, END_DATE_FORMAT)
    parsed_start_date.to_date
  end

  # obvious methods

  def parse_date(date, format)
    DateTime.strptime date, format
  end

  def safely_convert_to_float(input, row)
    begin
      input.to_f
    rescue => e
      CSLogger.error "---Error converting to float input=#{input}  row=#{row}"
      raise 'abort'
    end
  end

  def failed_to_save_cost_summary(cost_summary)
    CSLogger.error "---errors: #{cost_summary.errors.full_messages}"
  end
end
