namespace :template_costs do
  desc "Fetch the latest template services costs"
  task fetch_aws_costs: :environment do
    TemplateCostFetchWorker.perform_async
  end
end

