namespace :update_service do
  task created_by: :environment do
  	UpdateServiceCreatorWorker.perform_async
  end
end