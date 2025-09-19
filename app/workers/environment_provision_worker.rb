require 'pusher'

class EnvironmentProvisionWorker
  include Sidekiq::Worker

  sidekiq_options queue: :environments, retry: false, backtrace: true

  def output(id, message)
    CSLogger.info "DEPLOY OUTPUT: #{message}"
    Pusher[id].trigger('deploy_event', message)
  end

  def perform(id, user_id)
    Pusher.url = "http://587608a14cfc7c38e780:845db6a0341837c29e1d@api.pusherapp.com/apps/63754"

    user = User.find(user_id)
    environment = Environment.find(id)
    sleep 2

    env = environment.id

    output env, "Provisioning environment... #{environment.name}"

    environment.services.each do |service|
      output env, "Provisioning service... #{service.id}"

      ServiceProvisioner.new(service, user).provision
    end
  rescue Exception => e
    output env, e.inspect
    output env, e.backtrace
  end
end
