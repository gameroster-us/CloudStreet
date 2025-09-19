class CloudStreetExceptionHandlers::ServiceIsDependent < CloudStreetExceptionHandler
  DEFAULT_ERROR_CODE = 115
  DEFAULT_HTTP_CODE  = 400
  DEFAULT_ERROR_MSG  = 'Sorry you cannot detach internet gateway, because LoadBalancer or ElasticIP is associated with your vpc'

  def get_data 
    {
      id: error_obj.id, 
      name: error_obj.name,
      type: "dependent_service",
      state: error_obj.state
    }
  end
end
