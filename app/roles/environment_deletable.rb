class EnvironmentDeletable
  def self.delete(environment, user)
    if !environment.can_remove?
      CSLogger.info "Unable to delete environment from current state"
      return false
    end

    environment.desired_state = "deleted"
    environment.updated_by = user.id
    environment.save!

    environment.remove!

    errors = 0
    EnvironmentOrderable.new(environment).provision_order.each do |service|
      next unless service.support_terminate?
      # CSLogger.info.environment(environment.id, "Deleting service #{service.id} (#{service.type})")

      ServiceDeleter.delete(service.id, user.id) do |result|
        result.on_success { |service| CSLogger.info "Successfully deleted service: #{service.inspect}" }
        result.on_error { |error|
        CSLogger.error "Error deleting service: #{error.inspect}"
          errors += 1
        }
      end
    end

    if errors == 0
      environment.deleted!
      return true
    else
      CSLogger.error "Errors deleting services"
      environment.error!
      return false
    end
  rescue Exception => error
    CSLogger.error error.inspect
    CSLogger.error error.backtrace
    environment.error!
    raise error
  end
end
