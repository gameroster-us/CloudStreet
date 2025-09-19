class Templates::RevisionSearcher < CloudStreetService
  class << self
    def search(template, user, &block)
      events = Event.create_n_update_events.by_template(template.id)
      status Status, :success, events, &block
    end
  end
end
