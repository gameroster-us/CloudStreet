class EventSearcher < CloudStreetService
  def self.search(account, env_id, &block)
    account = fetch Account, account
    events = Event.where("data ->> 'environment_id'=?", env_id)
    status Status, :success, events, &block
    return events
  end
end