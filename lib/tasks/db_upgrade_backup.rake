namespace :pgdb do
  desc "Dumps the database to db/APP_NAME.dump"
  task :dump => :environment do
    with_config do |host, db, user, pass|
      dump_cmd = "export PGPASSWORD=#{pass}; pg_dump --host #{host} --username #{user} --no-owner --oids --no-acl --file /data/mount/#{db}_bckp.dump --format=t --dbname #{db}"
      CSLogger.info dump_cmd
      exec dump_cmd
    end
  end

  private

  def with_config
    yield ActiveRecord::Base.connection_config[:host],
    ActiveRecord::Base.connection_config[:database],
    ActiveRecord::Base.connection_config[:username],
    ActiveRecord::Base.connection_config[:password]
  end
end