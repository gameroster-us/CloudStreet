class MongodbService < ApplicationService
  class << self
    def process_migration(account, db_name)
      return if Mongoid.clients.keys.include?(db_name)
      file_path = File.exist?("/data/mount/mongoid.yml") ? "/data/mount/mongoid.yml" : "config/mongoid.yml"
      mongo_yml_path = Rails.root.join(file_path)
      database = Rails.env.test? ? "#{db_name}_report_test" : "#{db_name}_report"
      database_config = YAML.load(File.open(mongo_yml_path))
      hosts = database_config[Rails.env.to_s]['clients']['default']['hosts']
      if Rails.env.test?
        database_config[Rails.env.to_s]['clients'][db_name] = {
          database: database, hosts: hosts,
          options: {
            read: { mode: :secondary_preferred },
            max_pool_size: 100, min_pool_size: 30
          }
        }
      else
        database_config[Rails.env.to_s]['clients'][db_name] = {
          database: database, hosts: hosts,
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
end
