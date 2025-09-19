# EC2 -> GEM + JSON FILE
# ELB, EIP, EBS -> GEM
# RDS -> JSON FILE
class TemplateCosts::AWS < TemplateCost

  require 'open-uri'
  require 'hash'

  RDS_ENGINE_TYPE_MAP = {
    'oracle-se' => 'oracle',
    'oracle-ee' => 'oracle',
    'oracle-se1' => 'oracle',
    'oracle-se2' => 'oracle',
    'sqlserver-ee' => 'sql_server',
    'sqlserver-se' => 'sql_server',
    'sqlserver-ex' => 'sql_server',
    'sqlserver-web' => 'sql_server',
    'mysql' => 'mysql',
    'postgres' => 'postgres',
    'aurora' => 'aurora'
  }.freeze

  BASE = CommonConstants::TEMPLATE_COSTS[:base]
  INDEX = CommonConstants::TEMPLATE_COSTS[:index]
  COSTS_FOR = CommonConstants::TEMPLATE_COSTS[:costings_for] #AmazonRDS AmazonEC2

  module Rejectable
    def reject_zero_cost
      reject { |k, v| (v == 0.0 || v.nil?) }
    end
  end

  class << self

    def download_costings
      base_url = BASE
      index_url = base_url + INDEX
      `curl -o index_costings.json #{index_url}`
      file = File.new('index_costings.json', 'r')
      parsed_offers = Yajl::Parser.new.parse(file)
      file.close
      valid_region_codes = %w[af-south-1 ap-east-1 eu-south-1 eu-west-3 eu-north-1 me-south-1 ap-south-1 ap-southeast-1 ap-southeast-2 ap-northeast-1 eu-central-1 eu-west-1 sa-east-1 us-east-1 us-west-1 us-west-2 us-east-2 eu-west-2 ca-central-1 ap-northeast-2 us-gov-east-1 us-gov-west-1]
      threads = []
      COSTS_FOR.each do |service|
        service_url = parsed_offers['offers'][service]['currentRegionIndexUrl']
        service_index_file = "#{service.downcase}_region_index.json"
        url = base_url + service_url
        `curl -o #{service_index_file} #{url}`
        file = File.new(service_index_file, 'r')
        parsed_file = Yajl::Parser.new.parse(file)
        parsed_file["regions"].collect do |key, value|
          next unless valid_region_codes.include?(key)

          file_name = service.downcase + "-" + key
          serivce_price_url = base_url + value["currentVersionUrl"]
          pp "#{file_name} #{serivce_price_url}"
          threads << Thread.new {
            `curl -o "#{file_name}.json" "#{serivce_price_url}"`
          }
        end
      end
      threads.map(&:join)
      CSLogger.info "completed downloading files"
    end

    def read_dowloaded_data(fname, &block)
      file = File.open(fname)
      parsed_file = Yajl::Parser.new.parse(file)
      if fname.include?("amazonec2")
        keys = parsed_file["products"].map { |k, v| attributes = v["attributes"]; attributes["usagetype"].present? ? ( (attributes["usagetype"].include?("UnusedBox") || attributes["usagetype"].include?("BoxUsage")) ? (attributes["preInstalledSw"].blank? || attributes["preInstalledSw"].eql?("NA") ? k : nil) : nil) : k }.compact
      else
        keys = parsed_file["products"].keys
      end
      yield(parsed_file, keys)
    rescue StandardError => e
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end

    def select_product_by_family(parsed_file, family_name)
      parsed_file.select { |_, v| v["productFamily"].eql?(family_name) }
    end

    def read_elastic_ip_data(fname)
      file = File.open(fname)
      parsed_file = Yajl::Parser.new.parse(file)
      eip_products = select_product_by_family(parsed_file["products"], "IP Address")
      product_keys_data = eip_products.each_with_object({}) { |(k, v), h| attributes = v["attributes"]; h[attributes["group"]] = k if attributes["group"].present? && ["ElasticIP:Address", "ElasticIP:Remap", "ElasticIP:AdditionalAddress"].include?(attributes["group"]) }
      TemplateCosts::Parsers::ElasticIP.parse(parsed_file, product_keys_data)
    rescue StandardError => e
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end

    def read_ebs_data(fname)
      file = File.open(fname)
      parsed_file = Yajl::Parser.new.parse(file)

      ebs_products = select_product_by_family(parsed_file['products'], 'Storage')
      ebs_skus = ebs_products.each_with_object({}) { |(k, v), h| attributes = v['attributes']; h[attributes['volumeApiName']] = k }

      ebs_sys_operation_data = select_product_by_family(parsed_file['products'], 'System Operation')
      ebs_sys_operation_skus = ebs_sys_operation_data.each_with_object({}) do |(k, v), h|
        attributes = v['attributes']
        if attributes['location'].eql?('US East (N. Virginia)')
          h[attributes['usagetype']] = k
        else
          attributes['usagetype'].slice!(0..4)
          h[attributes['usagetype']] = k
        end
      end
      TemplateCosts::Parsers::Ebs.parse(parsed_file, ebs_skus, ebs_sys_operation_skus)
    rescue StandardError => e
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end

    def read_elb_data(fname)
      file = File.open(fname)
      parsed_file = Yajl::Parser.new.parse(file)
      classic_elb_products = select_product_by_family(parsed_file["products"], "Load Balancer")
      classic_elbs = classic_elb_products.each_with_object({}) { |(k, v), h| attributes = v["attributes"]; h[attributes["usagetype"]] = k if attributes["group"].eql?("ELB:Balancer")}
      TemplateCosts::Parsers::Elb.parse(parsed_file, classic_elbs)
    rescue StandardError => e
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end

    def read_nw_elb_data(fname)
      file = File.open(fname)
      parsed_file = Yajl::Parser.new.parse(file)
      nw_elb_products = select_product_by_family(parsed_file["products"], "Load Balancer-Network")
      nw_elbs = nw_elb_products.each_with_object({}) { |(k, v), h| attributes = v["attributes"]; h[attributes["usagetype"]] = k if attributes["groupDescription"].eql?("LoadBalancer hourly usage by Network Load Balancer") }
      TemplateCosts::Parsers::Elb.parse(parsed_file, nw_elbs)
    rescue StandardError => e
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end

    def read_app_elb_data(fname)
      file = File.open(fname)
      parsed_file = Yajl::Parser.new.parse(file)
      app_elb_products = select_product_by_family(parsed_file["products"], "Load Balancer-Application")
      app_elbs = app_elb_products.each_with_object({}) { |(k, v), h| attributes = v["attributes"]; h[attributes["usagetype"]] = k if attributes["groupDescription"].eql?("LoadBalancer hourly usage by Application Load Balancer")}
      TemplateCosts::Parsers::Elb.parse(parsed_file, app_elbs)
    rescue StandardError => e
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end

    def prepare_data(region, spot_pricing_data)
      ec2_data = prepare_ec2_data(region) || {}
      ec2_spot_instance_data = prepare_ec2_spot_data(region, spot_pricing_data) || {}
      ec2_ebs_data = prepare_ebs_data(region) || {}
      elastic_ips_data = prepare_elastic_ips_data(region) || {}
      ec2_elb_data = prepare_elb_data(region) || {}
      ec2_nw_elb_data = prepare_nw_elb_data(region) || {}
      ec2_app_elb_data = prepare_app_elb_data(region) || {}
      rds_data = prepare_rds_data(region) || {}
      eks_data = prepare_eks_data || {}
      multi_merge(ec2_data, ec2_spot_instance_data, ec2_ebs_data, elastic_ips_data, ec2_elb_data, ec2_nw_elb_data, ec2_app_elb_data, rds_data, eks_data)
    end

    def prepare_ec2_data(region)
      read_dowloaded_data("amazonec2-#{region.code}.json") do |parsed_file, keys|
        ec2_hash = {}
        keys.each do |key|
          get_parsed_data(key, parsed_file, ec2_hash, region)
        end
        aws_linux_cost = ec2_hash[region.code].reject { |k, v| k.nil? || k == "na" }["linux"]
        # awscost_linux_cost = connection.ec2.on_demand(:linux).price
        # linux_final_cost = get_final_merged_costing(aws_linux_cost, awscost_linux_cost)

        aws_windows_cost = ec2_hash[region.code].reject { |k, v| k.nil? || k == "na" }["windows"]
        # awscost_windows_cost = connection.ec2.on_demand(:windows).price
        # windows_final_cost = get_final_merged_costing(aws_windows_cost, awscost_windows_cost)

        aws_rhel_cost = ec2_hash[region.code].reject { |k, v| k.nil? || k == "na" }["rhel"]
        # awscost_rhel_cost = connection.ec2.on_demand(:rhel).price
        # rhel_final_cost = get_final_merged_costing(aws_rhel_cost, awscost_rhel_cost)

        aws_suse_cost = ec2_hash[region.code].reject { |k, v| k.nil? || k == "na" }["suse"]
        # awscost_suse_cost = connection.ec2.on_demand(:sles).price
        # suse_final_cost = get_final_merged_costing(aws_suse_cost, awscost_suse_cost)

        linux = {linux: aws_linux_cost}
        windows = {windows: aws_windows_cost}
        rhel = {rhel: aws_rhel_cost}
        suse = {suse: aws_suse_cost}
        # windows_with_sql_web = {windows_with_sql_web: connection.ec2.on_demand(:windows_with_sql_web).price }
        # windows_with_sql = { windows_with_sql: connection.ec2.on_demand(:windows_with_sql).price }
        {ec2: {on_demand: multi_merge(linux, windows, rhel, suse)}} #, windows_with_sql_web, windows_with_sql)}}
      end
    end

    def prepare_ec2_spot_data(region, spot_pricing_data)
      if region.code.eql?('us-gov-east-1')
        spot_linux = { linux: CommonConstants::US_GOV_EAST_1_SPOT_PRICING }
        spot_windows = { windows: CommonConstants::US_GOV_EAST_1_SPOT_PRICING }
      elsif region.code.eql?('us-gov-west-1')
        spot_linux = { linux: CommonConstants::US_GOV_WEST_1_SPOT_PRICING }
        spot_windows = { windows: CommonConstants::US_GOV_WEST_1_SPOT_PRICING }
      else
        linux_spot_instances_cost = {}
        windows_spot_instances_cost = {}
        spot_pricing_data['instanceTypes'].each do |instance_type|
          instance_type['sizes'].each do |i_size|
            size = i_size['size']
            i_size['valueColumns'].each do |value|
              if value['name'].eql?('linux')
                linux_spot_instances_cost[size] = value['prices']['USD'] == 'N/A*' ? 0.0 : value['prices']['USD'].to_f
              elsif value['name'].eql?('mswin')
                windows_spot_instances_cost[size] = value['prices']['USD'] == 'N/A*' ? 0.0 : value['prices']['USD'].to_f
              end
            end
          end
        end
        spot_linux = { linux: linux_spot_instances_cost }
        spot_windows = { windows: windows_spot_instances_cost }
      end
      { ec2_spot_instance: multi_merge(spot_linux, spot_windows) }
    end

    def get_final_merged_costing(hash1, hash2)
      h1 = hash1.blank? ? {} : hash1.extend(Rejectable).reject_zero_cost
      h2 = hash2.blank? ? {} : hash2.extend(Rejectable).reject_zero_cost
      h1.merge!(h2)
    end

    def prepare_ebs_data(region)
      {ec2_ebs: read_ebs_data("amazonec2-#{region.code}.json")}
    end

    def prepare_elastic_ips_data(region)
      # Right now no data is comming for elastic ip, so added static pricing for same.
      { elastic_ips: { "perRemapFirst100"=>0.0, "perRemapOver100"=>0.1, "perAdditionalEIPPerHour"=>0.005, "perNonAttachedPerHour"=>0.005 }}
      # if region.code.eql?("af-south-1") || region.code.eql?("eu-south-1")
      #   {elastic_ips: {"perRemapFirst100"=>0.0, "perRemapOver100"=>0.1, "perAdditionalEIPPerHour"=>0.005, "perNonAttachedPerHour"=>0.005}}
      # else
      #   # Fix for eu-west-2' EU (London) Region for ElasticIP:Address As not getting in EC2 cost files.
      #   # TODO Once AWS provides the cost for ElasticIP:Address need to change.
      #   {elastic_ips: region.code.eql?("eu-west-2") ? read_elastic_ip_data("amazonec2-#{region.code}.json").merge!("perNonAttachedPerHour"=>0.005) : read_elastic_ip_data("amazonec2-#{region.code}.json")}
      # end
    end

    def prepare_elb_data(region)
      {ec2_elb: read_elb_data("amazonec2-#{region.code}.json")}
    end

    def prepare_nw_elb_data(region)
      {ec2_nw_elb: read_nw_elb_data("amazonec2-#{region.code}.json")}
    end

    def prepare_app_elb_data(region)
      {ec2_app_elb: read_app_elb_data("amazonec2-#{region.code}.json")}
    end

    def prepare_rds_data(region)
      mysql_data = prepare_mysql_data(region) || {}
      postgres_data = prepare_postgres_data(region) || {}
      oracle_data = prepare_oracle_data(region) || {}
      sqlserver_data = prepare_sqlserver_data(region) || {}
      aurora_data = prepare_aurora_data(region) || {}
      per_gb_data = prepare_per_gb_data(region) || {}
      {rds: { on_demand: multi_merge({mysql: mysql_data}, {postgres: postgres_data}, {oracle: oracle_data}, {sql_server: sqlserver_data}, {aurora: aurora_data}), per_gb: per_gb_data}}
    end

    def prepare_eks_data()
      { eks: {"perHour" => 0.10 }} # EKS has fixed price $ 0.10
    end

    def prepare_per_gb_data(region)
      file = File.new("amazonrds-#{region.code}.json", 'r')
      parsed_file = Yajl::Parser.new.parse(file)
      file.close
      db_storage_keys = parsed_file['products'].inject([]) do |per_gb_array, (pf_key, pf_values)|
        if (pf_values['productFamily'] == 'Database Storage' || pf_values['productFamily'] == 'Provisioned IOPS') && pf_values['attributes']['location'] == region.region_name
          per_gb_array << pf_key
        end
        per_gb_array
      end
      typed_hash = {}
      if db_storage_keys
        db_storage_keys.each do |db_storage_key|
          is_multi_az = parsed_file["products"][db_storage_key]["attributes"]["deploymentOption"].include?('Multi-AZ') #true / false
          volume_type = (parsed_file["products"][db_storage_key]["attributes"]["volumeType"] || parsed_file["products"][db_storage_key]["attributes"]["group"]).try(:downcase).try(:tr, ' ', '_').try(:tr, '-', '_') #mangetic, etc
          price_per_unit = parsed_file["terms"]["OnDemand"][db_storage_key].deep_find("pricePerUnit")['USD'].to_f
          typed_hash[volume_type] ||= {}
          typed_hash[volume_type]['standard'] ||= 0
          typed_hash[volume_type]['multi_az'] ||= 0
          if is_multi_az
            typed_hash[volume_type]['multi_az'] = price_per_unit
          else
            typed_hash[volume_type]['standard'] = price_per_unit
          end
        end
      end
      typed_hash
    end
    # on_demand: { per_gb: { general_puporse: {standard: {}, multi_az: {}}, iops: {}} }

    def prepare_aurora_data(region)
      read_dowloaded_data("amazonrds-#{region.code}.json") do |parsed_file, keys|
        aurora_hash = {}
        keys.each do |key|
          engine = parsed_file["products"][key]["attributes"]["databaseEngine"].try(:downcase).try(:tr, ' ', '_')
          next(key) if (engine != "aurora_mysql")

          get_parsed_data(key, parsed_file, aurora_hash, region, "rds1")
        end
        multi_az = aurora_hash[region.code]['Multi-AZ'] rescue nil
        standard = aurora_hash[region.code]['Single-AZ'] rescue nil
        {multi_az: multi_az, standard: standard}
      end
    end

    def prepare_mysql_data(region)
      read_dowloaded_data("amazonrds-#{region.code}.json") do |parsed_file, keys|
        mysql_hash = {}
        keys.each do |key|
          engine = parsed_file["products"][key]["attributes"]["databaseEngine"].try(:downcase).try(:tr, ' ', '_')
          next(key) if (engine != "mysql")

          get_parsed_data(key, parsed_file, mysql_hash, region, "rds1")
        end
        multi_az = mysql_hash[region.code]['Multi-AZ']
        standard = mysql_hash[region.code]['Single-AZ']
        {multi_az: multi_az, standard: standard}
      end
    end

    def prepare_postgres_data(region)
      read_dowloaded_data("amazonrds-#{region.code}.json") do |parsed_file, keys|
        postgres_hash = {}
        keys.each do |key|
          engine = parsed_file["products"][key]["attributes"]["databaseEngine"].try(:downcase).try(:tr, ' ', '_')
          next(key) if (engine != "postgresql")

          get_parsed_data(key, parsed_file, postgres_hash, region, "rds1")
        end
        multi_az = postgres_hash[region.code]['Multi-AZ']
        standard = postgres_hash[region.code]['Single-AZ']
        {multi_az: multi_az, standard: standard}
      end
    end

    def prepare_oracle_data(region)
      read_dowloaded_data("amazonrds-#{region.code}.json") do |parsed_file, keys|
        oracle_hash = {}
        keys.each do |key|
          engine = parsed_file["products"][key]["attributes"]["databaseEngine"].try(:downcase).try(:tr, ' ', '_')
          next(key) if (engine != 'oracle')

          get_parsed_data(key, parsed_file, oracle_hash, region, "rds2")
        end
        multi_az = oracle_hash[region.code]['Multi-AZ']
        standard = oracle_hash[region.code]['Single-AZ']
        {multi_az: multi_az, standard: standard}
      end
    end

    def prepare_sqlserver_data(region)
      read_dowloaded_data("amazonrds-#{region.code}.json") do |parsed_file, keys|
        sqlserver_hash = {}
        keys.each do |key|
          engine = parsed_file["products"][key]["attributes"]["databaseEngine"].try(:downcase).try(:tr, ' ', '_')
          next(key) if engine != 'sql_server'

          get_parsed_data(key, parsed_file, sqlserver_hash, region, "rds2")
        end
        multi_az = sqlserver_hash[region.code]['Multi-AZ']
        standard = sqlserver_hash[region.code]['Single-AZ']
        {multi_az: multi_az, standard: standard}
      end
    end

    def merge_sql_data(arg1, arg2, arg3, arg4)
      first_merge = format_sql_data(arg1, arg2)
      second_merge = format_sql_data(first_merge, arg3)
      final_merged = format_sql_data(second_merge, arg4)
      return final_merged
    end

    def format_sql_data(arg1, arg2)
      hash = {}
      arg1.each do |k, v| #standard
        arg1[k.to_sym].each do |k1, v1| #t1micro, {:ex => {}, :web => {}}
          unless arg2[k.to_sym][k1].nil?
            v1.merge!(arg2[k.to_sym][k1]) { |k, a_val, _| a_val }
            arg2[k.to_sym].delete(k1)
          end
        end
      end
      hash.merge!(arg1)
      final_merge(arg2, hash)
    end

    def final_merge(arg2, hash)
      arg2.each do |k, v|
        hash[k].merge!(arg2[k])
      end
      return hash
    end

    def club_lic_and_non_lic(arg1, arg2, key_type="se1")
      final_hash = {}
      arg1.each do |k, v|
        if !arg2[k].nil?
          final_hash.merge!(k => {key_type.to_sym => v, byol_or_nolicense: arg2[k]})
        end
      end
      lic_reject = arg1.reject { |k, v| final_hash.keys.include? k }.inject({}) { |h, (k, v)| h[k] = {se1: v}; h }
      nl_lic_reject = arg2.reject { |k, v| final_hash.keys.include? k }.inject({}) { |h, (k, v)| h[k] = {byol_or_nolicense: v}; h }
      final_hash.merge! lic_reject
      final_hash.merge! nl_lic_reject
      final_hash
    end

    def get_parsed_data(key, parsed_file, hash, region, type="ec2")
      if type == "ec2"
        attribute = "operatingSystem"
      elsif (type == "rds1" || type == "rds2")
        attribute = "deploymentOption"
      end
      if (type == 'rds2' || type == 'rds1')
        if parsed_file['products'][key]['attributes']['location'] == region.region_name
          hash[region.code] ||= {}
          return if type == 'rds1' && parsed_file["products"][key]["attributes"][attribute].nil?

          hash[region.code][parsed_file["products"][key]["attributes"][attribute]] ||= {}
          return if type == 'rds1' && parsed_file["products"][key]["attributes"]["instanceType"].nil?

          hash[region.code][parsed_file["products"][key]["attributes"][attribute]][parsed_file["products"][key]["attributes"]["instanceType"]] ||= {}

          if parsed_file["products"][key]["attributes"]["licenseModel"] == "License included"
            unless ["M99NA55VPX8FMDGU", "C786DH8DAHYJSKMC"].include?(key) #special case for two specific keys, ignoring the values
              price = parsed_file["terms"]["OnDemand"][key].try(:deep_find, "pricePerUnit")
              pricePerUnit = price.nil? ? nil : price['USD']
              hash[region.code][parsed_file["products"][key]["attributes"][attribute]][parsed_file["products"][key]["attributes"]["instanceType"]].merge!(parsed_file["products"][key]["attributes"]["databaseEdition"].try(:downcase).try(:tr,' ', '_') => pricePerUnit) unless pricePerUnit.blank?
            end
          elsif parsed_file["products"][key]["attributes"]["licenseModel"] == "No license required"
            hash[region.code] ||= {}
            hash[region.code][parsed_file["products"][key]["attributes"][attribute]] ||= {}
            price = parsed_file["terms"]["OnDemand"][key].try(:deep_find, "pricePerUnit")
            pricePerUnit = price.nil? ? nil : price['USD']
            hash[region.code][parsed_file["products"][key]["attributes"][attribute]].merge!(parsed_file["products"][key]["attributes"]["instanceType"] => pricePerUnit) unless pricePerUnit.blank?
          else
            price = parsed_file["terms"]["OnDemand"][key].try(:deep_find, "pricePerUnit")
            pricePerUnit = price.nil? ? nil : price['USD']
            hash[region.code][parsed_file["products"][key]["attributes"][attribute]][parsed_file["products"][key]["attributes"]["instanceType"]].merge!("byol_or_nolicense" => pricePerUnit) unless pricePerUnit.blank?
          end
        end
      else
        if parsed_file["products"][key]["attributes"]["location"] == region.region_name
          hash[region.code] ||= {}
          hash[region.code][parsed_file["products"][key]["attributes"][attribute].try(:downcase)] ||= {}

          if parsed_file["terms"]["OnDemand"][key]
            if !hash[region.code][parsed_file["products"][key]["attributes"][attribute].try(:downcase)].has_key?(parsed_file["products"][key]["attributes"]["instanceType"]) && !parsed_file["terms"]["OnDemand"][key].deep_find("pricePerUnit")['USD'].to_f.eql?(0.0)
              # Special case handled for "r4.2xlarge" instance type cost mismatch issue.
              unless key.eql?("AZS3E5B5RMN3CZKC") && region.region_name.eql?("US West (Oregon)")
                hash[region.code][parsed_file["products"][key]["attributes"][attribute].try(:downcase)].merge!(
                  parsed_file["products"][key]["attributes"]["instanceType"] => parsed_file["terms"]["OnDemand"][key].deep_find("pricePerUnit")['USD'].to_f
                )
              end
            end
          end
        end
      end
    end

    def get_ec2_cost_by_region(region, platform)
      platform = 'linux' if platform.eql? 'non-windows'
      where(region_id: region).first.data[region.code]['ec2']['on_demand'][platform]
    end

    def get_rds_cost_by_region(region, engine, multi_az)
      engine = RDS_ENGINE_TYPE_MAP[engine]
      rds_class = multi_az ? 'multi_az' : 'standard'
      where(region_id: region).first.data[region.code]['rds']['on_demand'][engine][rds_class]
    end

  end

end
