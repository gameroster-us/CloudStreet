module GCP::Resource::CostCalculator::Compute::Image
  RESOURCE_PREFIX_DESCRIPTION = 'storage image'
  RESOURCE_GROUP_MAPPER = 'StorageImage'
  TEN_RAISE_TO_MINUS_NINE = 1000000000.0

  def calculate_hourly_cost
    CSLogger.info "#{self.id} => #{self.name} | Image Location Type : #{self.location_type} *************** In calculate_hourly_cost ****************"
    return 0.0 if self.archive_size_bytes == '0'

    service_region_code = fetch_service_region_code
    CSLogger.info "#{self.id} => Image Region Code : #{service_region_code}"

    return 0.0 if service_region_code.nil?

    image_data = GCP::ComputePricing.where("lower(description) LIKE ? AND resource_group = ? AND ? = ANY(service_regions)", RESOURCE_PREFIX_DESCRIPTION + '%', RESOURCE_GROUP_MAPPER, service_region_code)

    image_data_count = image_data.to_a.count
    # Remove this put statement after complete testing
    CSLogger.info "#{self.id} => Image Count : #{image_data_count}"

    # Refactor to_a bcuz count, length, size querng the data again
    return 0.0 unless image_data_count == 1

    image_price = fetch_image_price(image_data.first)
    CSLogger.info "#{self.id} => Image Price Per GB month: #{image_price}"

    total_image_price = calculate_image_total_price(image_price)
    total_image_price_hr = total_image_price / 730
    CSLogger.info "#{self.id} => Total | Price : #{total_image_price} | HR : #{total_image_price_hr}"

    total_image_price_hr
  end

  # Right now multi regional data pricing data is not available for image thats why adding defailt region in MR
  def fetch_service_region_code
    if self.location_type == 'Regional'
      self.region_code
    else
      'us-central1'
    end
  end

  def fetch_image_price(image_data)
    # Here after pricing info first will removed
    image_price = image_data.pricing_info['pricingExpression']['tieredRates']&.last['unitPrice']
    if image_price.key?('nanos') && image_price.key?('units') && (!image_price['nanos'].nil? || image_price['units'].present?)
      image_price['nanos']/TEN_RAISE_TO_MINUS_NINE + image_price['units'].to_i
    else
      0.0
    end
  end

  def calculate_image_total_price(image_price)
    size_in_gb = self.archive_size_bytes.to_i/(1024.0*1024.0*1024.0)
    image_price * size_in_gb
  end
end