module UserRoleRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL
  include MarketplaceUserRoleRepresenter if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'

  property :id, getter: lambda { |args| 
    args[:options][:object] = self
    args[:options][:object].id
  }
  property :name
  property :number_of_users
  property :created_at, getter: lambda { |*| created_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :updated_at, getter: lambda { |*| updated_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :provision_right
  property :sso_keywords
  property :mira

  unless ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
    link :self do |args|
      user_role_path(id)
    end

    link :remove do |args|
      user_role_path(id)
    end

    link :edit do |args|
      user_role_path(id)
    end
  end  
end
