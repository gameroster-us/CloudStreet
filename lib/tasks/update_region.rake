namespace :update_region do
  desc "Update account regions for newly added AWS regions"
  task update_account_regions_for_aws: :environment do
    aws_regions = Region.where(code: %w[af-south-1 ap-east-1 eu-south-1 eu-west-3 eu-north-1 me-south-1 ap-northeast-2 ap-south-1 us-east-2 eu-west-2 ca-central-1 us-gov-east-1 us-gov-west-1])
    Account.find_each do |account|
      aws_regions.each do |region|
        existing_account_region = AccountRegion.find_by(region_id: region.id, account_id: account.id)
        next unless existing_account_region.blank?

        acc_region = AccountRegion.new(region_id: region.id, account_id: account.id, enabled: true)
        if acc_region.valid?
          acc_region.save!
        else
          CSLogger.info "there were some errors while creating account region for account #{account.id} - #{acc_region.errors}"
        end
      end
    end
  end
  desc "Update Account Regions for Azure"
  task update_account_regions_for_azure: :environment do
    directory_adapter = Adapter.find_by(type: "Adapters::Azure", state: "directory")
    azure_regions = Region.where(adapter_id: directory_adapter.id)
    Account.all.each do |account|
      azure_regions.each do |region|
        existing_account_region = AccountRegion.find_by(region_id: region.id, account_id: account.id)
        AccountRegion.create!(region_id: region.id, account_id: account.id, enabled: true) unless existing_account_region
      end
    end
  end
  desc 'Update Account Regions for GCP'
  task update_account_regions_for_gcp: :environment do
    directory_adapter = Adapter.find_by(type: 'Adapters::GCP', state: 'directory')
    gcp_regions = Region.where(adapter_id: directory_adapter.id)
    Account.all.each do |account|
      gcp_regions.each do |region|
        existing_account_region = AccountRegion.find_by(region_id: region.id, account_id: account.id)
        AccountRegion.create!(region_id: region.id, account_id: account.id, enabled: true) unless existing_account_region
      end
    end
  end
end
