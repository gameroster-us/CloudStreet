namespace :aws do
  desc "AWS Ec2 Cost Updater by Athena data"
  task ec2_cost_updater: :environment do
    Organisation.active.find_each(batch_size: 50) do |organisation|
      Sync::BackgroundEc2CostUpdatorWorker.perform_async(organisation.id)
    end
  end

  desc "Checking Adapter Region Enabled worker"
  task check_adapter_region_enabled: :environment do
    region_codes = Region.aws.pluck(:code)
    Adapter.aws_adapter.active_adapters.normal_adapters.joins(account: :organisation).where(organisations: { is_active: true }).find_in_batches(batch_size: 60) do |adapter_batches|
      CheckAdapterRegionsEnabledWorker.perform_async(adapter_batches.map(&:id), region_codes)
    end
  end
end