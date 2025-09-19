class RdsDump

  FLAVOUR_SORT_ORDER =  ["db.t2.micro", "db.t2.small", "db.t2.medium", "db.t2.large", "db.t2.xlarge", "db.t2.2xlarge"]
  RDS_CLASS_SORT = %w[t1 t2 t3 m5 m4 m3 r3 m2 m1 cr1 r4 r5].freeze
  GENERIC_FLAVOUR_ORDER = ["micro", "small", "medium", "large", "xlarge", "2xlarge", "4xlarge", "6xlarge", "8xlarge", "10xlarge", "12xlarge", "16xlarge", "24xlarge"]

  def initialize(adapter, region=nil)
    @adapter = adapter
    @region = region
  end

  def store_parsed_data
    # RdsFlavorVersionData.destroy_all
    fetch_and_store_rds_data
  end

  def fetch_and_store_rds_data
    if @region
      raw_data = fetch_data_from_aws(@adapter, @region)
    else
      CommonConstants::REGIONS.each do |region_code|
        RdsDumpWorker.perform_async(region_code)
      end
    end
  end

  def sort_basic_flavours(arr1, sort_order)
    basic_sorted_flavours = arr1.collect { |ele| ele if GENERIC_FLAVOUR_ORDER.any? { |f| ele.include?(f) } }.compact.sort_by { |e| GENERIC_FLAVOUR_ORDER.index{ |d| e =~ /#{d}/ } }
    large_eles = arr1.select { |e| e =~ /\.large/ }
    sorted_xlarge_eles = sort_arr(arr1.select { |ele| ele.include?("xlarge") })
    # basic_sorted_flavours + large_eles + sorted_xlarge_eles
    basic_sorted_flavours
  end

  def sort_arr(arr, pattern='xlarge')
    return [] if arr.reject(&:blank?).empty?
    el = arr.shift
    less, more = arr.partition { |e| e.split('.').last.delete(pattern).to_i < el.split('.').last.delete(pattern).to_i }
    sort_arr(less, pattern) + [el] + sort_arr(more, pattern)
  end

  def get_sorted_flavours(raw_flavours)
    raw_flavours.each do |version, instance_sizes|
      sortable_hash ||= {}
      sortable_hash[version] ||= {}
      grouped_instances =  instance_sizes.group_by { |is| is.split('.').second }
      grouped_instances.each do |instance_class, flavours_to_sort|
        # CloudStreet.log "instance_class: #{instance_class}"
        if RDS_CLASS_SORT.include? instance_class
          _sorted = sort_arr(flavours_to_sort, pattern='xlarge')
          # CloudStreet.log "_sorted: #{_sorted}"
          _sorted_f = sort_basic_flavours(_sorted, sort_order=FLAVOUR_SORT_ORDER)
          # CloudStreet.log "_sorted_f: #{_sorted_f}"
          sortable_hash[version][instance_class] = _sorted_f
          # CloudStreet.log "version: #{version}======#{version.class}===========sortable_hash: #{sortable_hash}"
          sortable_hash[version] = sortable_hash[version].slice(*RDS_CLASS_SORT) # can be removed
          CloudStreet.log "sortable_hash[version] #{sortable_hash[version]}"
          raw_flavours[version] = sortable_hash[version].sort_by { |k,v| RDS_CLASS_SORT.index(k) }.to_h.values.flatten
        end
      end
    end
    raw_flavours.to_json
  end

  def dump_parse_data(region_code)
    instance_type_hash = {}
    rds_versions_hash = {}
    region_obj = Region.find_by_code region_code
    instance_type_hash[region_code] = {}
    rds_versions_hash[region_code] = {}
    Services::Database::Rds::AWS::SUPPORTED_ENGINES.each do |engine|
      instance_type_hash[region_code][engine] ||= {}
      rds_versions_hash[region_code][engine] ||= []
      begin
        if ["us-gov-east-1", "us-gov-west-1"].include?(region_code)
          credentials = ProviderWrappers::AWS.get_aws_helper_account_credentials_for_us_gov
        else
          credentials = ProviderWrappers::AWS.get_aws_helper_account_credentials
        end
        session_token = "AWS_SESSION_TOKEN=#{credentials[:aws_session_token]}"
        response = JSON.parse(`AWS_ACCESS_KEY_ID=#{credentials[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{credentials[:aws_secret_access_key]} #{session_token||""} aws rds  describe-orderable-db-instance-options --region #{region_code} --engine #{engine}`)
        # adapter = Adapters::AWS.get_default_adapter
        # return if adapter.blank?
        # session_token = "AWS_SESSION_TOKEN=#{adapter.aws_session_token}" if adapter.aws_session_token
        # response = JSON.parse(`AWS_ACCESS_KEY_ID=#{adapter.access_key_id} AWS_SECRET_ACCESS_KEY=#{adapter.secret_access_key} #{session_token||""} aws rds  describe-orderable-db-instance-options --region #{region_code} --engine #{engine}`)
        # CloudStreet.log "response: #{response}"
        response_hash = response["OrderableDBInstanceOptions"]
        response_hash.uniq.inject([]) do |res, hash|
          instance_type_hash[region_code][engine][hash['EngineVersion']] ||= []
          rds_versions_hash[region_code][engine] ||= []
          instance_type_hash[region_code][engine][hash['EngineVersion']] << hash['DBInstanceClass'] unless instance_type_hash[region_code][engine][hash['EngineVersion']].include?(hash['DBInstanceClass'])
          rds_versions_hash[region_code][engine] << hash['EngineVersion']
          rds_versions_hash[region_code][engine] = rds_versions_hash[region_code][engine].uniq
        end
      rescue => e
        CloudStreet.log "Error while fetching instances for RDS for #{engine}----region #{region_code}"
        CloudStreet.log "#{e.message}"
        CloudStreet.log "#{e.backtrace}"
        next(engine)
      end
      if RdsFlavorVersionData.where(region_code: region_code, engine: engine).first
        RdsFlavorVersionData.where(region_code: region_code, engine: engine).set(flavours: get_sorted_flavours(instance_type_hash[region_code][engine]), versions: rds_versions_hash[region_code][engine].reverse.to_json)
      else
        # CloudStreet.log "Creating for region #{region_code} ane Engine #{engine}"
        RdsFlavorVersionData.create(region_id: region_obj.id, region_code: region_code, engine: engine,  flavours: get_sorted_flavours(instance_type_hash[region_code][engine]), versions: rds_versions_hash[region_code][engine].reverse.to_json)
      end
    end
    CloudStreet.log "Dumped for region -- #{region_code}"
  end
end
