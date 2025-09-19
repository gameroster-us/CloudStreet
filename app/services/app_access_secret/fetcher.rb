class AppAccessSecret::Fetcher < CloudStreetService

  class << self

    def exec(organisation, user, &block)
      app_access_secrets = user.app_access_secrets.where(organisation_id: organisation.id)
      status Status, :success, app_access_secrets, &block
    end

  end

end
