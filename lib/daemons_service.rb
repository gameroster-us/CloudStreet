# require 'daemons'

# options = {
#   app_name: "log_receiver",
#   dir_mode: :script,
#   dir: "../tmp/pids",
#   multiple: true,
#   backtrace: true,
#   monitor: true
# }
class DaemonsService
  def service(name)
    Daemons.run_proc(name) do
  
      Signal.trap("HUP") { $stdout.CSLogger.info "I SHALL NOT EXIT" }
  
      require File.expand_path('../config/boot', File.dirname(__FILE__))
      require File.expand_path('../config/application', File.dirname(__FILE__))
  
      CSLogger.info "[+] Starting #{name}"
  
      Rails.application.require_environment!
  
      # CSLogger.info "STARTING UP WORKFLOWER AIGHT?"
  
      CloudStreet.name = name
      Log4r::GDC.set(name)
  
      yield
  
      thr = Thread.new { loop { sleep 1 } }
  
      begin
        thr.join
      rescue SystemExit, Interrupt
        CSLogger.info "Exiting app yo"
        # thr.stop
        exit
  #    rescue Exception => e # FIXME: don't catch Exception
  #      CSLogger.error "Uncaught exception :o"
      end
    end
  end
end 
