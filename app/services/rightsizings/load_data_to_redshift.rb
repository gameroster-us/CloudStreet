require 'csv'
class Rightsizings::LoadDataToRedshift < ApplicationService
  attr_accessor :db

  def initialize
    # connect to Redshift
    r = Rightsizings::Redshift.new
    endpoint = r.get_end_point
    @db = PG.connect(
      host: endpoint,
      port: Settings.port,
      user: Settings.master_username,
      password: Settings.master_user_password,
      dbname: Settings.db_name,
    )
  end

  def load_price_list_to_redshift
    truncate_all_table
    headers = get_headers_from_price_list_csv
    load_price_list_data_to_redshift(headers)
    add_regionabbr_to_price_list_table
    set_region_code_to_price_list
    delete_zero_entry_from_price_list
  end

  def truncate_all_table
    begin
      db.exec <<-EOS
      TRUNCATE #{CommonConstants::TABLE_PRICE_LISTING};
      EOS
    rescue Exception => e
      CSLogger.error "Error while truncating table #{e.message}"
      raise e
    end
  end

  def get_headers_from_price_list_csv
    begin
      file_name = "Rightsizing/ec2pricelist.csv.gz"
      if File.exist?(file_name)
        system(`gunzip  #{file_name}`)
         # Remove readlines bcuz it was reading whole file and the file size is now 2.6 gb
        line = ""
        file = File.new("Rightsizing/ec2pricelist.csv")
        file.each_with_index do |row, ind|
          if ind == 5
            line = row
            break
          end
        end
        file.close
        headers = CSV.parse(line).flatten.map! { |col| col.gsub(' ', '').gsub('/', '').gsub('-', '').gsub('"', '') }
        headers = headers.map { |col| col == 'Group' ? 'GroupID' : col }
      end
    rescue Exception => e
      CSLogger.error "Exception while getting headers from price list csv #{e.message}"
      raise e
    end
  end

  def load_price_list_data_to_redshift(headers)
    begin
      CSLogger.info "loading price_list_csv to s3 redshift...wait for while..."
      db.exec <<-EOS
      COPY #{CommonConstants::TABLE_PRICE_LISTING} (#{headers.join(', ')})
      FROM 's3://#{Settings.right_size_bucket_name + "-" + ENV["REDSHIFT_REGION_ID"]}/#{CommonConstants::TABLE_PRICE_LISTING}/price_listing'
      CREDENTIALS 'aws_access_key_id=#{CommonConstants::DEFAULT_KEYS[:access_key_id]};aws_secret_access_key=#{CommonConstants::DEFAULT_KEYS[:secret_access_key]}'
      DELIMITER ','
      IGNOREHEADER 6
      CSV
      EMPTYASNULL
      GZIP
      EOS
      CSLogger.info "Loaded price list csv to redshift successfully... "
    rescue Exception => e
      CSLogger.error "Exception while loading price list csv to redshit #{e.message}"
      raise e
    end
  end

  def add_regionabbr_to_price_list_table
    begin
      alter_price_list = "alter table price_listing add regionabbr varchar(300)"
      db.exec(alter_price_list)
      CSLogger.info "Alter query executed successfully"
    rescue PG::DuplicateColumn => e
      CSLogger.error "Column exists #{e.message}"
      raise e
    end
  end

  def set_region_code_to_price_list
    begin
      update_pricelist_sql = "update price_listing set regionabbr=case "
      update_pricelist_sql += " when location='US West (Oregon)' then 'USW2' "
      update_pricelist_sql += " when location='US East (N. Virginia)' then 'USE1' "
      update_pricelist_sql += " when location='US West (N. California)' then 'USW1' "
      update_pricelist_sql += " when location='Asia Pacific (Seoul)' then 'APN2' "
      update_pricelist_sql += " when location='Asia Pacific (Singapore)' then 'APS1' "
      update_pricelist_sql += " when location='Asia Pacific (Sydney)' then 'APS2' "
      update_pricelist_sql += " when location='Asia Pacific (Tokyo)' then 'APN1' "
      update_pricelist_sql += " when location='EU (Frankfurt)' then 'EU' "
      update_pricelist_sql += " when location='EU (Ireland)' then 'EUW1' "
      update_pricelist_sql += " when location='South America (Sao Paulo)' then 'SAE1' "
      update_pricelist_sql += " when location='Asia Pacific (Mumbai)' then 'APS1' "
      update_pricelist_sql += " end "
      db.exec(update_pricelist_sql)
      CSLogger.info "Update query executed successfully"
    rescue Exception => e
      CSLogger.error "Exception occured #{e.message}"
      raise e
    end
  end

  def delete_zero_entry_from_price_list
    begin
      zero_entry_pricelist = "delete from price_listing where to_number(trim(both ' ' from priceperunit),'999999999999D9999999999999') <= 0.00"
      db.exec(zero_entry_pricelist)
      CSLogger.info "Zero entries have been deleted successfully"
    rescue Exception => e
      CSLogger.error "Exception occured #{e.message}"
      raise e
    end
  end

  def load_right_size_data_to_redshift(account_id)
    CSLogger.info "Loading rightsize data to redshift for account--> #{account_id}"
    begin
      db.exec <<-EOS
      COPY #{CommonConstants::TABLE_RIGHT_SIZING} (#{CommonConstants::RIGHT_SIZE_COLUMNS.join(', ')})
      FROM 's3://#{Settings.right_size_bucket_name + "-" + ENV["REDSHIFT_REGION_ID"]}/#{CommonConstants::TABLE_RIGHT_SIZING}/#{account_id}'
      CREDENTIALS 'aws_access_key_id=#{CommonConstants::DEFAULT_KEYS[:access_key_id]};aws_secret_access_key=#{CommonConstants::DEFAULT_KEYS[:secret_access_key]}'
      IGNOREHEADER 0
      CSV
      EMPTYASNULL
      GZIP
      EOS
    rescue Exception => e
      CSLogger.error "Error while coping data to redshift #{e.message}"
    end
  end

end
