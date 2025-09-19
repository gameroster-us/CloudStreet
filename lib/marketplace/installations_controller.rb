class InstallationsController < ApplicationController

  def verify_db_connection
    begin
      result = Installation.verify_db_connection(db_params)       
      respond_to do |format|
        format.json { render json: {message: I18n.t('db_connection_success')}, status: 200 } if result
        format.json { render json: {message:  (db_params[:db_new_installation] == true || db_params[:db_new_installation] == 'true') ?  I18n.t('invalid_new_db') : I18n.t('invalid_existing_db')}, status: 422 } unless result
      end
    rescue ActiveRecord::NoDatabaseError => exception
      db_not_found_error(exception)
    rescue PG::ConnectionBad => exception
      connection_bad_error(exception)
    rescue RuntimeError => exception
      existing_db_error(exception)
    end
  end
  
  def init_database
    begin
      respond_to do |format|
        if db_params[:db_new_installation] == true || db_params[:db_new_installation] == 'true'
          format.json { render json: {message: I18n.t('db_connection_success')}, status: 200 }
        else
          result = Installation.get_existing_data(db_params)
          format.json { render json: {message: result}, status: 200 }
        end
      end
    rescue ActiveRecord::NoDatabaseError => exception
      db_not_found_error(exception)
    rescue PG::ConnectionBad => exception
      connection_bad_error(exception)
    rescue RuntimeError => exception
      existing_db_error(exception)
    end
  end

  def send_test_email
    begin
      Installation.send_test_email(smtp_params)
      respond_to do |format|
        format.json { render json: {message: I18n.t('sent_email')}, status: 200 }
      end
    rescue Net::OpenTimeout => exception
      smtp_port_error(exception)
    rescue SocketError => exception
      smtp_host_error(exception)
    rescue Net::SMTPAuthenticationError => exception
      smtp_auth_error(exception)
    end
  end

  def verify_internet_connection
    begin
      result = Installation.verify_internet_connection(proxy_params)
      respond_to do |format|
        format.json { render json: result.slice(:message), status: (result[:success] ? 200 :422)}
      end
    rescue OpenURI::HTTPError => exception
      CSLogger.error exception.inspect
      render json: {
      message: I18n.t('http_auth_failed'),
      system_message: (exception.class.to_s + exception.message)
      }, status: 500
    rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ECONNREFUSED, Timeout::Error => exception
      CSLogger.error exception.inspect
      error_msg = I18n.t('proxy_connection_failed') if proxy_params['set_proxy']== 'true'
      error_msg = I18n.t('internet_access_failed') unless proxy_params['set_proxy']== 'true'
      render json: {
      message: error_msg,
      system_message: (exception.class.to_s + exception.message)
      }, status: 500    
    rescue SocketError => exception
      render json: {message: I18n.t('proxy_connection_failed')}, status: 422
    end
  end

  def set_network_config
    respond_to do |format|
      format.json { render json: {message: I18n.t('net_config_saved')}, status: 200 }
    end
  end

  def update_proxy_vars
    CSLogger.info "proxy_params-------------------------------#{proxy_params.inspect}"
    if proxy_params['noproxy'] && proxy_params['noproxy'].last.exclude?(',')
      proxy_params['noproxy'] = proxy_params['noproxy'] + ','
    end
    Verification.export_proxy_env_vars(proxy_params)
    system("api_container_id=$(docker ps | grep api | awk '{print$1}')")

    container_id = `docker ps | grep api | awk '{print$1}'`.strip
    system("docker exec -i #{container_id} /bin/bash /data/api/current/script/proxy_upgrade.sh")

    respond_to do |format|
      format.json { render json: {message: I18n.t('env_vars_updated')}, status: 200 }
    end
    # docker service reload
    # inside container proxy vars update
    # call upgrade.sh 
  end

  def register_organisation
    begin
      session["init"] = true    
      session[:installation] = organisation_params
      response = Installation.init_server(session[:installation])
      respond_to do |format|
        format.json {
          if response[:status]==:success
            render json: {message: I18n.t('successfull_wiz_complete')}, status: 200
          elsif response[:status] == :error_new_installation
            render json: {errors: response[:errors]}, status: 422
          else
            render json: {error: I18n.t(response[:status])}, status: 500
          end
        }
      end
    rescue ActiveRecord::NoDatabaseError => exception
      db_not_found_error(exception)
    rescue PG::ConnectionBad => exception
      connection_bad_error(exception)
    rescue RuntimeError => exception
      existing_db_error(exception)
    rescue Exception => e
      render json: {errors: response[:errors]}, status: 500
    end
  end

  def initiate_upgrade
    Thread.new{
    # query_params = params.with_indifferent_access if params
    #script_file = File.read('/home/cloudstreet/mount/script_file.sh')    
    system("sudo chown -R cloudstreet:cloudstreet /home/cloudstreet/mount/script_file.sh")	
    #system("sudo chown -R cloudstreet:cloudstreet /home/cloudstreet/mount/restore_script_runner.sh")  
    #script_res = %x(bash '/home/cloudstreet/mount/restore_script_runner.sh')      
    if system('bash /home/cloudstreet/mount/script_file.sh')
#       CSLogger.info "PARAMS-------#{params}-"
      db_details = YAML.load(File.read("/home/cloudstreet/mount/database.yml"))[Rails.env]
      ActiveRecord::Base.establish_connection(db_details) if db_details
      if ActiveRecord::Base.connection.active?
        org_info = OrganisationDetail.first 
        latest_version = org_info.data['latest_version']
        org_info.data['current_version'] = latest_version
        org_info.data_will_change!
        org_info.save
      end
    end
    }
    render json: {response: nil}, status: 200  
  end 

  def update_ssl
    CSLogger.info "update ssl === ssl #{params.inspect}"
   if params['use_own'].eql?('true') || params['use_own'].eql?(true)
     system "sudo bash /home/cloudstreet/mount/ssl_setup.sh use_client_ssl.sh"
   else
     system "sudo bash /home/cloudstreet/mount/ssl_setup.sh use_self_signed.sh"
   end
   render json: {message: 'success'}, status: 200
  end

private
  
  def organisation_params
    org_params = {}
    org_params[:database_config] = JSON.parse(params[:ref][:init_database])
    org_params[:network_config] = JSON.parse(params[:ref][:set_network_config])
    org_params[:organisation_info] = params.slice(:sign_up)
    org_params[:organisation_info][:sign_up].merge!('host_'=> params['host_'])
    CSLogger.info org_params.inspect
    org_params
  end

  def smtp_params
    params.permit(:smtp_address, :smtp_port, :smtp_username, :smtp_password, :smtp_from_email, :set_smtp, :smtp_to_email)
  end

  def proxy_params
    params.permit(:net_ip, :net_port, :net_username, :net_password, :set_proxy, :noproxy)
  end

  def db_params
    params.permit(:db_host, :db_port, :db_username, :db_password, :db_database, :db_new_installation)
  end

  def smtp_port_error(exception)
    render json: {
      message: I18n.t('smtp_port_invalid'),
      system_message: (exception.class.to_s + exception.message)
    }, status: 500    
  end

  def smtp_host_error(exception)
    render json: {
      message: I18n.t('smtp_host_unknown'),
      system_message: (exception.class.to_s + exception.message)
    }, status: 500    
  end

  def smtp_auth_error(exception)
    render json: {
      message: I18n.t('smtp_credentials_invalid'),
      system_message: (exception.class.to_s + exception.message)
    }, status: 500    
  end

  def existing_db_error(exception)
    render json: {
      message: I18n.t('invalid_existing_db'),
      system_message: (exception.class.to_s + exception.message)
    }, status: 500
  end

  def show_errors(exception)
    CSLogger.error exception.message
    CSLogger.error exception.backtrace
    CSLogger.error exception.class.to_s
    render json: {
      message: I18n.t('internal_server_error_message'),
      system_message: (exception.class.to_s + exception.message)
    }, status: 500
  end

  def db_not_found_error(exception)
    render json: {
      message: I18n.t('invalid_db_details'),
      system_message: (exception.class.to_s + exception.message)
    }, status: 500
  end

  def connection_bad_error(exception)
    render json: {
      message: I18n.t("connection_bad", system_msg: exception.message),
      system_message: (exception.class.to_s + exception.message)
    }, status: 500
  end

end
