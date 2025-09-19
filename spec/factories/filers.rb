# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :filer do
    data {{"svm_name"=>"svm_Test", "creator_user_email"=>"user@example.com", "status"=>{"status"=>"ON", "message"=>"", "failureCauses"=>{"invalidOntapCredentials"=>false, "noCloudProviderConnection"=>false, "invalidCloudProviderCredentials"=>false}, "extendedFailureReason"=>nil}, "aws_properties"=>nil, "reserved_size"=>nil, "encryption_properties"=>nil, "cluster_properties"=>nil, "ontap_cluster_properties"=>nil, "actions_required"=>nil, "inter_cluster_lifs"=>nil, "cron_job_schedules"=>nil, "snapshot_policies"=>nil, "svms"=>nil, "active_actions"=>nil, "replication_properties"=>nil, "schedules"=>nil, "cloud_provider_name"=>"Amazon", "is_ha"=>false, "working_environment_type"=>"VSA", "support_registration_properties"=>nil, "support_registration_information"=>[], "ha_properties"=>nil, "capacity_features"=>nil}}
    cloud_resource_adapter
    account
    public_id "VsaWorkingEnvironment-C8jfFXCW"
    name "Test"
    tenant_id "Tenant-4RcmUFVx"
    type 'Filers::CloudResources::NetApp'
    enabled true
  end
end
