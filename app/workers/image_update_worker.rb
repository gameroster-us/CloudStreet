class ImageUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(environment_id, user_id, template_id=nil)
    user = User.where(id: user_id).first
    ::Images::ImageUpdator.update_on_environment(environment_id, user, template_id)
  end
end