namespace :mongodb do
  desc "Update mongodb yml for report databases"
  task update_yml: :environment do
    Adapters::AWS.cost_trackable_accounts.pluck(:id).each do |account_id|
      account = Account.find_by(id: account_id)
      db_name = account.organisation_identifier
      process_migration(account, db_name)
    end
  end

  def process_migration(account, db_name)
    file_path = File.exist?("/data/mount/mongoid.yml") ? "/data/mount/mongoid.yml" : "config/mongoid.yml"
    mongo_yml_path = Rails.root.join(file_path)
    return if Mongoid.clients.keys.include?(db_name)
    database_config = YAML.load(File.open(mongo_yml_path))
    hosts = database_config[Rails.env.to_s]['clients']['default']['hosts']
    if Rails.env.test?
      database_config[Rails.env.to_s]['clients'][db_name] = {
        database: "#{db_name}_report", hosts: hosts,
        options: {
          read: { mode: :secondary_preferred },
          max_pool_size: 100, min_pool_size: 30
        }
      }
    else
      database_config[Rails.env.to_s]['clients'][db_name] = {
        database: "#{db_name}_report", hosts: hosts,
        options: {
          read: { mode: :secondary_preferred },
          max_pool_size: 100, min_pool_size: 30,
          ssl: true, ssl_verify: false,
          user: 'admin',
          password: "#{ENV['MONGODB_PASSWORD']}",
          auth_source: 'admin'
        }
      }
    end
    File.open(mongo_yml_path, 'w') { |f| f.write(database_config.to_yaml) }
    Mongoid.load!(mongo_yml_path)
  rescue StandardError => e
    CSLogger.error e.message
  end
end