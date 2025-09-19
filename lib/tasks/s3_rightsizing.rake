# rake s3_rightsizing:FetchS3ForRightSizing
namespace :s3_rightsizing do
  desc 'Fetching S3 Organisation Wise'
  task :FetchS3ForRightSizing => [:environment] do
    begin
      CSLogger.info '= Started Rake Task for S3 Right Sizing ='
      S3RightSizing::CallerWorker.perform_async
    rescue StandardError => e
      CSLogger.error "* Exception in the rake task Fetch S3 Right Sizing | Excpetion Message : #{e.message} *"
    end
  end
end
