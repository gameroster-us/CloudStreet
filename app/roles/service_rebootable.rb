class ServiceRebootable
  def self.reboot(service)
    
    service.desired_state = "running"
    service.save!

    service.reboot_service
    service.rebooted

    return true
  
  rescue Exception => error
    CSLogger.error error.inspect
    CSLogger.error error.backtrace
    service.error!
    raise error
  end
end
