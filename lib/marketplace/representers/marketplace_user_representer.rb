module MarketplaceUserRepresenter
include Roar::JSON
include Roar::Hypermedia
include Roar::JSON::HAL

  property :admin , getter: lambda { |args| self.is_marketplace_ami_admin? }
  property :ami_preferences
  property :saml_user  

  # link :self do |args|
  #   user_path(id) if args[:options][:current_user].can_read?(self)
  # end

  # link :remove do |args|
  #   user_path(id) if args[:options][:current_user].can_delete?(self)
  # end

  # link :edit do |args|
  #   user_path(id) if args[:options][:current_user].can_update?(self)
  # end
end
