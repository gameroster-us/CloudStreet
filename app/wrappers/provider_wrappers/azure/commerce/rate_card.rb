class ProviderWrappers::Azure::Commerce::RateCard < ProviderWrappers::Azure

  def get(offer_id, currency="USD", locale="en-US", region_info="US")
    filter_params = "OfferDurableId eq '#{offer_id}' and Currency eq '#{currency}' and Locale eq '#{locale}' and RegionInfo eq '#{region_info}'"
    client.api_version = "2016-08-31-preview"
    res = client.rate_card.get(filter_params)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  rescue MsRest::HttpOperationError => e
    if e.response.status.eql?(302)
      res = HTTParty.get(e.response.headers[:location])
      return @response.set_response(:success, res)
    end
    @response.set_response(:error, e.response, e.body)
  end

end
