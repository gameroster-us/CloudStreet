class Rightsizings::RedshiftTableService < ApplicationService

  def self.create_tables(r)
    CSLogger.info "Inside create_tables for right_sizing_data"
    count = 0
    table_not_created = true
    while table_not_created || count == 60
      status = r.get_cluster_status
      CSLogger.info "Current cluster Status --->#{status}"
      if status.eql?("available")
        endpoint = r.get_end_point
        db = Rightsizings::RedshiftTableService.get_pg_connection(endpoint)
        Rightsizings::RedshiftTableService.create_right_sizing_data_table(db)
        Rightsizings::RedshiftTableService.create_price_listing_table(db)
        table_not_created = false
        CSLogger.info "redshift tables created successfully..."
      else
        sleep(60)
        CSLogger.info "Creating redshift tables....wait for clusters to up...#{count}"
        count += 1
        table_not_created = false if count == 60
      end
    end
  end

  def self.get_pg_connection(endpoint)
    PG.connect(
      host: endpoint,
      port: 5439,
      user: Settings.master_username,
      password: Settings.master_user_password,
      dbname: Settings.db_name
    )
  rescue Exception => e
    CSLogger.error "Exception--- #{e.message}"
  end

  def self.create_right_sizing_data_table(db)
    table_name = "right_sizing_data"
    create_table_sql = "create table " + table_name + "( "
    CommonConstants::RIGHT_SIZE_COLUMNS.each { |col| create_table_sql += " " + col + (col.eql?('instanceTags') ? " varchar(60000) ," : " varchar(60000) ,") }
    create_table_sql = create_table_sql[0..-2] + " )"
    begin
      db.exec(create_table_sql)
    rescue Exception => e
      CSLogger.error e.message
    end
  end

  def self.create_price_listing_table(db)
    if File.exist?("Rightsizing/ec2pricelist.csv")
      # Remove readlines bcuz it was reading whole file and the file size is now 2.6 gb
      line = ''
      file = File.new("Rightsizing/ec2pricelist.csv")
      file.each_with_index do |row, ind|
        if ind == 5
          line = row
          break
        end
      end
      file.close
      headers = CSV.parse(line).flatten.map! { |col| col.gsub(' ', '').gsub('/', '').gsub('-', '').gsub('"', '') }
      table_name = "price_listing"
      create_table_sql = "create table " + table_name + "( "
      headers.each do |col|
        col = "GroupId" if col.eql?("Group")
        create_table_sql += " " + col + " varchar(300) ,"
      end

      create_table_sql = create_table_sql[0..-2] + " )"
      begin
        db.exec(create_table_sql)
      rescue Exception => e
        CSLogger.error e.message
      end
    end
  end

end
