# require "spec_helper"
# describe Synchronizers::AWS::SynchronizerService do
  # before(:all) do
  #   @account = FactoryBot.create(:account, :with_user)
  #   @current_user = @account.users.first
  # end

  # describe ".attach_service_to_environment" do

  #   before(:all){
  #     @region = FactoryBot.create(:region)
  #     @adapter = FactoryBot.create(:adapter,:aws)
  #     @environment = FactoryBot.create(:environment, region: @region, account: @account, default_adapter: @adapter)
  #     @service = FactoryBot.create(:service, :volume_aws, region: @region, account: @account, adapter: @adapter)
  #   }

  #   let(:exec_method){ Synchronizers::AWS::SynchronizerService.attach_service_to_environment(@service.id, @environment.id) {} }
  #   let(:env_service_ids) { @environment.services.pluck :id }

  #   context "when service belongs to a different account" do
  #     it "should not add the service to the environment" do
  #       @service.update_attributes(account: FactoryBot.create(:account))
  #       exec_method
  #       expect(env_service_ids).to_not include @service.id
  #     end
  #   end

  #   context "when environment belongs to a different account" do
  #     it "should not add the service to the environment" do
  #       @environment.update_attributes(account: FactoryBot.create(:account))
  #       exec_method
  #       expect(env_service_ids).to_not include @service.id
  #     end
  #   end

  #   context "when environment belongs to a different region" do
  #     it "should not add the service to the environment" do
  #       @environment.update_attributes(region: FactoryBot.create(:region))
  #       exec_method
  #       expect(env_service_ids).to_not include @service.id
  #     end
  #   end

  #   context "when environment belongs to a different adapter" do
  #     it "should not add the service to the environment" do
  #       @environment.update_attributes(default_adapter: FactoryBot.create(:adapter,:aws))
  #       exec_method
  #       expect(env_service_ids).to_not include @service.id
  #     end
  #   end

  #   context "when service already assigned to environment" do
  #     it "should not add the service to the environment again" do
  #       @environment.services << @service
  #       before_count = @environment.services.count
  #       exec_method
  #       after_count = @environment.services.count
  #       expect(before_count).to eql after_count
  #     end
  #   end

  #   context "when successfully assigned the service" do
  #     it "should include the service in the environments service" do
  #       exec_method
  #       expect(env_service_ids).to include @service.id
  #     end
  #   end
  # end

  # describe ".list_synchronized_services" do
  #   let(:services){ Synchronizers::AWS::SynchronizerService.list_synchronized_services(@current_user) {} }

  #   it "returns a list" do
  #     expect(services).to be_a Array
  #   end

  #   it "returns a list of services" do
  #     services.each do |service|
  #       expect(service).to be_a Service
  #     end
  #   end

  #   it "does not return the services used in a template" do
  #     templated_service = FactoryBot.build(:service, :volume_aws, :templated, :with_provider_id)
  #     expect(services).to_not include templated_service
  #   end

  #   it "does not return the services used in an environment" do
  #     environmented_service = FactoryBot.build(:service, :volume_aws, :environmented, :with_provider_id)
  #     expect(services).to_not include @environmented_service
  #   end

  #   context "when a service has been synchronized" do
  #     it "returns the services that are synchronized" do
  #       @synced_service = FactoryBot.create(:service, :volume_aws, :running, account: @account, data: {server_id: nil})
  #       synchronized_service_ids = services.map(&:id)
  #       expect(synchronized_service_ids).to include @synced_service.id
  #     end
  #   end
  # end

  # describe ".synchronize_service" do
    # let(:synced_service_ids){
    #   @account.get_synced_unattached_services.map(&:provider_id)
    # }
    # context "when service has not been synchronized before" do
    #   before(:all) do
    #     @unattached_volume = FactoryBot.create(:aws_volume, :detached)
    #     @account.aws_records << @unattached_volume
    #   end

    #   it "creates the service" do
    #     FactoryBot.create_list(:synchronization, 1, account: @account)
    #     Synchronizers::AWS::SynchronizerService.synchronize_service(@current_user, @unattached_volume.provider_id) {}
    #     expect(synced_service_ids).to include @unattached_volume.provider_id
    #   end
    # end

    # context "when service has been synchronized before" do
    #   before(:all) do
    #     @synced_volume = FactoryBot.build(:service, :volume_aws, :with_provider_id)
    #     @account.services << @synced_volume
    #   end
    #   context "and has been deleted from provider" do
    #     it "deletes the service from cloudstreet" do
    #       Synchronizers::AWS::SynchronizerService.synchronize_service(@current_user, @synced_volume.provider_id) {}
    #       expect(synced_service_ids).to_not include @synced_volume.provider_id
    #     end
    #   end
    # end
  # end
  # describe ".list_unattached_volumes_to_be_synced" do
  #   let(:return_value) do
  #     Synchronizers::AWS::SynchronizerService.list_unattached_volumes_to_be_synced(@current_user) {}
  #   end
    # it "returns an empty list when synchronization has not yet been scheduled" do
    #   expect(return_value).to be_empty
    # end
    # it "returns an empty list when last scheduled synchronization failed" do
    #   @account.synchronization_logs << FactoryBot.create(:synchronization, :failed, account: @account)
    #   expect(return_value).to be_empty
    # end
    # context "when successfully synchronized" do
    #   before(:all) do
    #     @account.synchronization_logs << FactoryBot.create(:synchronization, :success, account: @account)
    #   end
    #   it "returns a list" do
    #     expect(return_value).to be_a Array
    #   end

    #   it "returns a list of volumes" do
    #     @account.aws_records << FactoryBot.create(:aws_server)
    #     @account.aws_records << FactoryBot.create(:aws_volume, :detached)

    #     return_value.each do |service|
    #       expect(service.generic_type).to eql Services::Compute::Server::Volume.to_s
    #     end
    #   end
      # context "when services fetched contain some volumes that are attached to servers and some volumes that are not" do
      #   before(:all) do
      #     @volume_attached = FactoryBot.create(:aws_volume, :attached)
      #     @unattached_volume = FactoryBot.create(:aws_volume, :detached)
      #     @account.aws_records << @volume_attached
      #     @account.aws_records << @unattached_volume
      #   end
      #   it "returns the volumes that are attached to any server" do
      #     resulting_volume_ids = return_value.map(&:provider_id)
      #     expect(resulting_volume_ids).to include @unattached_volume.provider_id
      #   end

      #   it "excludes the volumes that are already attached to a server" do
      #     resulting_volume_ids = return_value.map(&:provider_id)
      #     expect(resulting_volume_ids).to_not include @volume_attached.provider_id
      #   end

        # context "when services fetched are associated to an environment" do

        #   it "includes only those volumes that are not used in any environment" do
        #     synced_volume = FactoryBot.build(:service, :volume_aws, {provider_id: @unattached_volume.provider_id})
        #     @account.services << synced_volume
        #     resulting_volume_ids = return_value.map(&:provider_id)
        #     expect(resulting_volume_ids).to include synced_volume.provider_id
        #   end

        #   it "excludes the volumes that are used in an environment" do
        #     environmented_volume = FactoryBot.build(:service, :volume_aws, :environmented, {provider_id: @unattached_volume.provider_id})
        #     @account.services << environmented_volume
        #     resulting_volume_ids = return_value.map(&:provider_id)
        #     expect(resulting_volume_ids).to_not include environmented_volume.provider_id
        #   end
        # end

      #   context "when volumes fetched were synchronized before but not fetched as they were deleted from provider" do
      #     it "includes those volumes" do
      #       synced_volume = FactoryBot.build(:service, :volume_aws, :running, :with_provider_id, {data: {server_id: nil}})
      #       @account.services << synced_volume
      #       resulting_volume_ids = return_value.map(&:provider_id)
      #       expect(resulting_volume_ids).to include synced_volume.provider_id
      #     end
      #   end
      #   it "includes one occurrence of those volumes that were synced before and were again fetched from provider" do
      #     synced_volume = FactoryBot.build(:service,:volume_aws,{provider_id: @unattached_volume.provider_id})
      #     resulting_volume_ids = return_value.map(&:provider_id)
      #     expect(resulting_volume_ids).to include synced_volume.provider_id
      #     expect(resulting_volume_ids.count).to eql (resulting_volume_ids.uniq.count)
      #   end
      # end
    # end
  # end
# end
