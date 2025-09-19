class RestClientService < CloudStreetService
  class << self
    def execute(method_type, url = nil, user = nil, params = {}, &block)
      host_component = Settings.host.split("//")
      subdomain = params.fetch(:subdomain)
      params = params.except(:subdomain)
      organisation = Organisation.find_by(subdomain: subdomain)
      response = RestClient::Request.execute(
        method: method_type,
        url: url,
        headers: {
          Authorization: "Bearer #{user.jwt_auth_token(organisation)}",
          WEB_HOST: "#{host_component[0]}//#{subdomain}.#{host_component[1]}",
          params: params
        },
        verify_ssl: false
      )
      JSON.parse(response) rescue response
    rescue StandardError => e
      CSLogger.error "RestClientService Error ===> #{e.message}\n#{e.backtrace}"
      { error: e.class, message: e.message }
    end

    def method_missing(method_name, *args, &block)
      execute(method_name, *args, &block)
    end
  end
end
