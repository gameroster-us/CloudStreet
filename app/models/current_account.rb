class CurrentAccount
  def self.client_db
    Thread.current[:client_db]
  end

  def self.active_adapters
    adapters = Thread.current[:account].adapters
    adapters.where(type: "Adapters::AWS", state: ['active', 'created']).where.not(data: nil)
  end

  def self.client_db=(account)
    client_db = account.try(:organisation_identifier)
    if Rails.env.test?
      MongodbService.process_migration(account,client_db)
    else
      Mongoid.load!(CommonConstants::MONGOID_YML) unless Mongoid.clients.keys.include?(client_db)
    end
    client_db = 'default' unless Mongoid.clients.keys.include?(client_db)
    Thread.current[:account] = account
    Thread.current[:client_db] = client_db
  end

  def self.account_id
    Thread.current[:account].try(:id)
  end

  def self.account=(account)
    Thread.current[:account] = account
  end
end
