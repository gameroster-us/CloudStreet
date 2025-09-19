class RdsConfigService < CloudStreetService
  DATABASES = Services::Database::Rds::AWS.all.collect { |d| d['data'] }.compact.collect { |d| d['engine'] }.reject(&:blank?).each { |d| d.gsub!('-','_') }
  RDS_GENERATION_ORDER =  %w[t1 t2 t3 m5 m4 m3 r3 m2 m1 cr1 r4 r5].freeze
  RDS_INSTANCE_SIZE_ORDER = %w["micro", "small", "medium", "large", "xlarge", "2xlarge", "4xlarge", "6xlarge", "8xlarge", "10xlarge", "12xlarge", "16xlarge", "24xlarge"].freeze

  SORT_FLAVOURS = lambda { |flavours|
    flavours.sort_by! do |flavour|
      RDS_GENERATION_ORDER.index(flavour.split(".")[1])
    end

    grouped_flavours = flavours.group_by { |v| v.split(".")[1] }.each { |k,flavours| flavours.sort_by!{ |flavour|
        RDS_INSTANCE_SIZE_ORDER.index(flavour.split(".").last) || flavours.size
      }
    }
    return grouped_flavours.values.flatten rescue []
  }
  class << self
    def get_rds_data(&block)
      rds_flavours = RdsFlavorVersionData.get_unique_rds_flavours_by_engine
      rds_flavours.each do |key,values|
        rds_flavours[key] = SORT_FLAVOURS.call(values)
      end
      status Status, :success, rds_flavours, &block
      return rds_flavours
    end

    def get_sorted_flavours_list(engine,region_code)
      rds_flavours = JSON.parse(RdsFlavorVersionData.where(engine: engine, region_code: region_code).first.flavours) rescue nil
      return {} if rds_flavours.blank?
      rds_flavours.each do |key,values|
        rds_flavours[key] = SORT_FLAVOURS.call(values)
      end
      return rds_flavours
    end

    def search(account, page_params, &block)
      configs = RdsConfiguration.where(:account_id => account.id)

      configs, total_records = apply_pagination(configs, page_params)

      status Status, :success, [configs, total_records], &block
    end

    def create(user, organisation, config_params, &block)
      config_params.delete_if {|k,v| k =="action" || k == "controller"}
      config_params = insert_all_config(config_params)
      config = RdsConfiguration.new config_params
      config.account = organisation.account
      config.creator = user
      config.updator = user
      if config.valid?
        if config.save
          status TagStatus, :success, config, &block
        else
          status Status, :validation_error, config.errors.messages, &block
        end
     else
      status Status, :validation_error, config.errors.messages, &block
     end
     return config
    end

    def insert_all_config(params)
      DATABASES.each do |database|
        unless params['data'].keys.include?(database)
          next if !params['data'][database].nil?
          params['data'][database] = {}
          params['data'][database] = {"-1" => []}
        end
      end
      params
    end

    def parse_hash(hash)
      hash.each do |k,v|
        if v.nil?
          hash[k] = []
        end
      end
      hash
    end

    def update(config, organisation, config_params, user, &block)
      config_params.delete_if {|k,v| k =="action" || k == "controller"}
      params = config_params['data']
      config.account = organisation.account
      config.creator = user
      config.updator = user
      params.keys.each do |attri|
        config.data[attri] =  parse_hash(params[attri])
      end
      if config.valid?
        config.data_will_change!
        if config.save
          status Status, :success, config, &block
        else
          status Status, :validation_error, config.errors.messages, &block
        end
      else
        status Status, :validation_error, config.errors.messages, &block
      end
     return config
    end
  end
end

