$customerio = Customerio::Client.new(
  Rails.configuration.customerio[:site_id],
  Rails.configuration.customerio[:api_key], :json => true)

$customerioApiClient = Customerio::APIClient.new(
  Rails.configuration.customerio[:api_client_key]
  )
