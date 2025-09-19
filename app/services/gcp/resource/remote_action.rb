module GCP::Resource::RemoteAction
  def self.included(receiver)
    module_name = "GCP::Resource::RemoteActions#{receiver.to_s.split('Resource').last}".constantize rescue nil
    receiver.include module_name unless module_name.blank?
  end
end