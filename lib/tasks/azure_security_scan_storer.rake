namespace :azure_security_scan_storer do
  desc 'Update explorer users rights'
  task store_data: :environment do
    Account.all.each do |account|
      CSLogger.info '=================Started fetching azure security scanner data'
      SecurityScanners::Azure::SecurityScanStorerWorker.perform_async(account.id)
    end
  end
end
