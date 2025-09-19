class AccountUpdater < CloudStreetService
  def self.update(account, params, user, &block)
    account = fetch Account, account

    if account.update(params)
      status Status, :success, account, &block
      return account
    else
      status Status, :error, "Failed to update! I should be a custom handler! Argh!", &block
      return nil
    end
  end

  def self.update_certs(account, params, &block)
    account = fetch Account, account
    org_detail = OrganisationDetail.last

    unless Account.update_cert_files(params)
      status Status, :error, "Failed to update!", &block
      return nil
    end

    org_detail.data['ssl_config'] = params
    org_detail.data_will_change!
    if org_detail.save
      docker_host_ip = `route -n | awk '/UG[ \t]/{print $2}'`.strip
      host = Settings.host.gsub('https', 'http')
      uri = URI("http://#{docker_host_ip}:9511/install/update_ssl?use_own=#{params[:use_own]}")
      script_res = Net::HTTP.start(uri.host, 9511) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        http.request request 
      end
      status Status, :success, account, &block
      return account
    else
      status Status, :error, "Failed to update!", &block
      return nil
    end
  end 
end
