module Verification
  SCRIPTS_PATH = "/data/api/current/script/"
  SCRIPTS_PATH_WEB = "/data/web/current/script/"
  SCRIPTS_PATH_REPORT = '/home/cloudstreet/report/script/'

	# class ActiveRecord::Base < ActiveRecord::Base
	# 	self.abstract_class = true
	# end

	def self.verify_db(db_params)
		init_connection(db_params)
		if ActiveRecord::Base.connection.active?       
			if db_params[:db_new_installation] == false || db_params[:db_new_installation] == 'false'
				is_valid_db = validate_existing_db
			else
				is_valid_db = validate_new_db
			end
			destroy_connection
			is_valid_db
		end	
	end

	def self.validate_existing_db
		ActiveRecord::Base.connection.table_exists?('organisation_details') && ActiveRecord::Base.connection.table_exists?('schema_migrations')		
	end

	def self.validate_new_db
		!(ActiveRecord::Base.connection.table_exists?('organisation_details') || ActiveRecord::Base.connection.table_exists?('schema_migrations'))
	end

	def self.init_connection(db_params)
		specs = {
      adapter: "postgresql",
      port:  db_params[:db_port].to_i,
      host: db_params[:db_host],
      username: db_params[:db_username],
      password: db_params[:db_password],
      database: db_params[:db_database]
    }
    ActiveRecord::Base.establish_connection(specs)
	end

	def self.destroy_connection
		ActiveRecord::Base.connection.disconnect! if ActiveRecord::Base.connection.active?
	end

	def self.export_proxy_env_vars(proxy_params)
    proxy_params = self.senitize_params(proxy_params)
    if (proxy_params[:set_proxy] == 'true' || proxy_params[:set_proxy] == true) && proxy_params[:net_ip].present? && proxy_params[:net_port].present?
      if proxy_params[:net_username].present? && proxy_params[:net_password].present?
        system("bash /home/cloudstreet/marketplace-api/scripts/http_yes_docker.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]} #{proxy_params[:net_username]}: #{proxy_params[:net_password]}@")
        system("bash /home/cloudstreet/marketplace-api/scripts/http_yes_setup.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]} #{proxy_params[:net_username]}: #{proxy_params[:net_password]}@")
        container_id = `docker ps | grep api | awk '{print$1}'`.strip
        web_container_id = `docker ps | grep web | awk '{print$1}'`.strip
        report_container_id = `docker ps | grep report | awk '{print$1}'`.strip
        system("docker exec -i #{container_id} /bin/bash #{SCRIPTS_PATH}http_yes_setup.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]} #{proxy_params[:net_username]}: #{proxy_params[:net_password]}@ #{proxy_params[:noproxy]}")
        system("docker exec -i #{web_container_id} /bin/bash #{SCRIPTS_PATH_WEB}http_yes_setup.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]} #{proxy_params[:net_username]}: #{proxy_params[:net_password]}@ #{proxy_params[:noproxy]}")
        system("docker exec -i #{report_container_id} /bin/bash #{SCRIPTS_PATH_REPORT}http_yes_setup.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]} #{proxy_params[:net_username]}: #{proxy_params[:net_password]}@ #{proxy_params[:noproxy]}")
      else
        system("bash /home/cloudstreet/marketplace-api/scripts/http_yes_docker.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]}")
        system("bash /home/cloudstreet/marketplace-api/scripts/http_yes_setup.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]}")
        container_id = `docker ps | grep api | awk '{print$1}'`.strip
        web_container_id = `docker ps | grep web | awk '{print$1}'`.strip
        report_container_id = `docker ps | grep report | awk '{print$1}'`.strip
        system("docker exec -i #{container_id} /bin/bash #{SCRIPTS_PATH}http_yes_setup.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]} #{proxy_params[:noproxy]}")
        system("docker exec -i #{web_container_id} /bin/bash #{SCRIPTS_PATH_WEB}http_yes_setup.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]} #{proxy_params[:noproxy]}")
        system("docker exec -i #{report_container_id} /bin/bash #{SCRIPTS_PATH_REPORT}http_yes_setup.sh #{proxy_params[:net_ip]} #{proxy_params[:net_port]} #{proxy_params[:noproxy]}")
      end
    else
      system("bash /home/cloudstreet/marketplace-api/scripts/http_remove_docker.sh")
      system("bash /home/cloudstreet/marketplace-api/scripts/http_remove_setup.sh")
      container_id = `docker ps | grep api | awk '{print$1}'`.strip
      web_container_id = `docker ps | grep web | awk '{print$1}'`.strip
      report_container_id = `docker ps | grep report | awk '{print$1}'`.strip
      system("docker exec -i #{container_id} /bin/bash #{SCRIPTS_PATH}http_remove_setup.sh")
      system("docker exec -i #{web_container_id} /bin/bash #{SCRIPTS_PATH_WEB}http_remove_setup.sh")
      system("docker exec -i #{report_container_id} /bin/bash #{SCRIPTS_PATH_REPORT}http_remove_setup.sh")
    end
  end 

  def self.verify_network_connection(proxy_params)
    if (proxy_params[:set_proxy] == 'true' || proxy_params[:set_proxy] == true) && proxy_params[:net_ip].present? && proxy_params[:net_port].present?
      proxy_url = "http://#{proxy_params[:net_ip]}:#{proxy_params[:net_port]}"
      connection_result = Timeout::timeout(20) {
        if proxy_params[:net_username].present? && proxy_params[:net_password].present?
          open("http://www.google.com/", :proxy_http_basic_authentication => [proxy_url, proxy_params[:net_username], proxy_params[:net_password]])
        else
          open("http://www.google.com/", proxy: proxy_url)
        end
      }
    else
       connection_result = Timeout::timeout(20) {
        open("http://www.google.com/", proxy: nil)
      }
    end
    return true if(connection_result.class == Tempfile || connection_result.class == StringIO)
    false    
  end

  def self.send_test_email(smtp_params)
    if smtp_params[:set_smtp] == 'true'|| smtp_params[:set_smtp] == true
      set_smtp_setting(smtp_params)
      ActionMailer::Base.mail(
        :from => smtp_params[:smtp_from_email], 
        :to => smtp_params[:smtp_to_email], 
        :subject => "Test Mail", 
        :body => "This is a test email"
      ).deliver
    else
      customerio = Customerio::Client.new(
        ENV['CUSTOMERIO_SITE_ID'],
        ENV['CUSTOMERIO_API_KEY'])      

      customerio.identify(
       id:         1,
       created_at: Time.now,
       email:      smtp_params[:smtp_to_email],
       name:       'testname',
       username:   'testusername')

      customerio.track(
      1,
      :test_email,
      email: smtp_params[:smtp_to_email])
    end  
  end
  
  def self.set_smtp_setting(smtp_params)
    ActionMailer::Base.smtp_settings = {
      :enable_starttls_auto => true,
      :address        => smtp_params[:smtp_address],
      :port           => smtp_params[:smtp_port].to_i,
      :authentication => :plain,
      :user_name      => smtp_params[:smtp_username],
      :password       => smtp_params[:smtp_password]
    }    
  end


  def self.setup_server(data, &block)
    db_info = data[:database_config]
    email_info = data[:network_config]['smtp']
    Bundler.with_clean_env do
      #system("sudo chown -R cloudstreet:cloudstreet /data/api/current/")
      #system("sudo chown -R cloudstreet:cloudstreet /data/web/current/")
      container_id = `docker ps | grep api | awk '{print$1}'`.strip
      report_container_id = `docker ps | grep report | awk '{print$1}'`.strip
      #system("sh #{SCRIPTS_PATH}db_vars_setter.sh #{db_info['db_host']} #{db_info['db_port']} #{db_info['db_database']} #{db_info['db_username']} #{db_info['db_password']}")
      system("docker exec -i #{container_id} /bin/bash #{SCRIPTS_PATH}db_vars_setter.sh #{db_info['db_host']} #{db_info['db_port']} #{db_info['db_database']} #{db_info['db_username']} #{db_info['db_password']}")
      #system("sh #{SCRIPTS_PATH}smtp_vars_setter.sh #{email_info['smtp_address']} #{email_info['smtp_port']} #{email_info['smtp_username']} #{email_info['smtp_password']} #{email_info['set_smtp']} #{email_info['smtp_from_email']}")
      system("docker exec -i #{container_id} /bin/bash #{SCRIPTS_PATH}env_vars_setter.sh ORG_SETUP complete")
      web_container_id = `docker ps | grep web | awk '{print$1}'`.strip
      system("docker exec -i #{web_container_id} /bin/bash #{SCRIPTS_PATH_WEB}env_vars_setter.sh ORG_SETUP complete")
      if db_info['db_new_installation'] == true || db_info['db_new_installation'] == 'true'
        system("docker exec -i #{container_id} /bin/bash #{SCRIPTS_PATH}reboot.sh #{db_info['db_host']} #{db_info['db_port']} #{db_info['db_database']} #{db_info['db_username']} #{db_info['db_password']} ")
        system("docker exec -i #{report_container_id} /bin/bash #{SCRIPTS_PATH_REPORT}new_isnatllation.sh")
      else
        Installation.save_organisation_details(data)
	      system("docker exec -i #{container_id} /bin/bash #{SCRIPTS_PATH}restart.sh #{db_info['db_host']} #{db_info['db_port']} #{db_info['db_database']} #{db_info['db_username']} #{db_info['db_password']} ")
        system("docker exec -i #{report_container_id} /bin/bash #{SCRIPTS_PATH_REPORT}existing_installation.sh")
        #system("sh #{SCRIPTS_PATH}restart.sh #{db_info['db_host']} #{db_info['db_port']} #{db_info['db_database']} #{db_info['db_username']} #{db_info['db_password']} ")
      end 
    end
    sleep(15)    
    block.call
  end

  def self.set_smtp_env_vars(smtp_config)
    smtp_config = self.senitize_params(smtp_config)
    container_id = `docker ps | grep api | awk '{print$1}'`.strip
    system("docker exec -i #{container_id} /bin/bash #{SCRIPTS_PATH}smtp_vars_setter.sh #{smtp_config[:smtp_address]} #{smtp_config[:smtp_port]} #{smtp_config[:smtp_username]} #{smtp_config[:smtp_password]} #{smtp_config[:set_smtp]} #{smtp_config[:smtp_from_email]}")
  end

  def self.senitize_params(params)
    permited_params = params.each do |k, v|
      ActionController::Base.helpers.sanitize(v)
    end
    permited_params
  end

end