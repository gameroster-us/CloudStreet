module Azure::Resource::RemoteActions::Web::AppServicePlan
  def resync
    res = client.get(resource_group_name, name)
    res.with_formatter(self.class.get_remote_resource_formatter_klass.constantize)

    res.on_error do |error_code, error_message, data|
      if error_message.eql?("404 Not Found")
        update_attribute(:state, :deleted)
        CSLogger.error "App Service Plan If resync error code: #{error_code}, message: #{error_message}, resource_name: #{name}, resource_id: #{id}"
        return :success, self
      else
        CSLogger.error "App Service Plan Else resync error code: #{error_code}, message: #{error_message}, resource_name: #{name}, resource_id: #{id}"
        return :error, {error_message: error_message, error_code: error_code}
      end
    end
    CSLogger.info "App Service Resource resync resource_name: #{name}, resource_id: #{id}"
    return :success, self
  rescue StandardError => e
    return :error, {error_message: e.message}
  end
end