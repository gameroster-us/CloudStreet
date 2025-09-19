namespace :solr_indexes do
  desc "Delete all solr indexes"
  task remove: :environment do
    CSLogger.info '-------Deleting all the indexed data in solr'
    Sunspot.remove_all!
    CSLogger.info '-------Deleted all the indexed data in solr'
  end

  desc "Create all solr indexes"
  task create: :environment do
    CSLogger.info '-------Started indexing data in data in solr'
    begin
      Rake::Task['sunspot:reindex'].invoke
      CSLogger.info '-------Successfully indexed solr data'
    rescue Exception => e
      CSLogger.error "Exception in solr create index- #{e.message} #{e.backtrace}"
    end
  end
end