module Azure::Resource::RemoteActions::Network::RouteTable
  def create_or_update_resource_route(route_params)
    args = [resource_group_name, name, route_params]
    client_route.run_remote_action(:create_or_update, *args) do |status, response|
      return :error, response if status.eql?(:error)

      index = routes.index { |h| h["name"] == route_params["name"] }
      index ? routes[index] = route_params : routes.push(route_params)

      return :success, self if save

      return :validation_error, errors
    end
  rescue StandardError => e
    return :error, {error_message: e.message}
  end

  def delete_resource_route(route_name)
    args = [resource_group_name, name, route_name]
    client_route.run_remote_action(:delete, *args) do |status, response|
      return :error, response if status.eql?(:error)

      index = routes.index { |h| h["name"] == route_name }
      routes.delete_at(index) if index >= 0

      return :success, self if save

      return :validation_error, errors
    end
  rescue StandardError => e
    return :error, {error_message: e.message}
  end
end
