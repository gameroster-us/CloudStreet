
#rake 'athena_group_table_check:check_presence'
namespace :athena_group_table_check do
  desc "Checking athena group table exist or not for organisation"
  task check_presence: :environment do
    CSLogger.info "******* Group Table checking started #{DateTime.now} ********"
    AthenaTableCheckerWorker.perform_async
  end
end