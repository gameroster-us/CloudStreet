# require 'spec_helper'
# module Filers
#   module CloudResources
#     describe NetAppService do
#       before(:all) do
#         @account ||= FactoryBot.create(:account,:with_user)
#         @user    ||= @account.users.first
#         @env     ||= http_login(@user)
#         @params  ||={}
#         @cloud_resource_adapter = FactoryBot.create(:cloud_resource_adapter, account: @account)
#         @sample_login_response = [true, OpenStruct.new(:body => {'name' => 'test'}, :response => {'set-cookie'=> 'somecooklie'})]
#         @sample_filer_response = [true, OpenStruct.new(body:
#                                   [
#                                       {
#                                         "publicId" => "VsaWorkingEnvironment-C8jfFXCW",
#                                         "name" => "Test",
#                                         "tenantId" => "Tenant-4RcmUFVx",
#                                         "svmName" => nil,
#                                         "creatorUserEmail" => "user@example.com",
#                                         "status" => {
#                                           "status" => "STARTING",
#                                           "message" => "",
#                                           "failureCauses" => {
#                                             "invalidOntapCredentials" => false,
#                                             "noCloudProviderConnection" => false,
#                                             "invalidCloudProviderCredentials" => false
#                                             },
#                                             "extendedFailureReason" => nil
#                                             },

#                                         "cloudProviderName" => "Amazon",
#                                         "isHA" => false,
#                                         "workingEnvironmentType" => "VSA",
#                                       }
#                                     ])
#                                   ]

#       end
#       describe '#search' do
#         it "should return the result filers with matched params" do
          #:id, :name, :public_id, :tenant_id, :data, :account_id, :cloud_resource_adapter_id
#           FactoryBot.create(:filer, account: @account, cloud_resource_adapter: @cloud_resource_adapter)
#           params = {name: 'Test'}
#           result = Filers::CloudResources::NetAppService.search(@account, params)
#           expect(result.pluck(:name)).to include('Test')
#         end
#         it "should have 0 results if the filer is not found" do
#           params = {name: 'NotFound'}
#           result = Filers::CloudResources::NetAppService.search(@account, params)
#           expect(result.count).to eq(0)
#         end
#         it "should return nil if no params are passed" do
#           result = Filers::CloudResources::NetAppService.search(@account, nil)
#           expect(result).to eq(nil)
#         end
#       end


#       describe '#synchronize filers' do
#         before(:each) do
#           allow(Sidekiq).to receive(:redis).and_return(MockRedis.new)
#           allow_any_instance_of(ProviderWrappers::NetAppAdapter).to receive(:login).and_return(@sample_login_response)
#           @params = {:wenv_type => 'vsa', :args => ['status'], :cloud_resource_adapter_id => @cloud_resource_adapter.id}
#         end
#         it "should return false and shall not create any record if some error occured while synchronization" do
#           filer_count = Filers::CloudResources::NetApp.count
#           result = Filers::CloudResources::NetAppService.synchronize_filers(@account_id, nil)
#           expect(result).to eq(false)
#           expect(Filers::CloudResources::NetApp.count).to eq(filer_count)
#         end

#         it "should synchronize filers and save in database" do
#           stub_request(:get, "http://192.168.10.32/occm/api/vsa/working-environments?fields=Status,clusterProperties").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => @sample_filer_response.last.body.to_json , :headers => {})
#           filer_count = Filers::CloudResources::NetApp.count
#           result = Filers::CloudResources::NetAppService.synchronize_filers(@account_id, @params)
#           expect(Filers::CloudResources::NetApp.count).to eq(filer_count+1)
#         end

#         it "should update the changed attributes for existing filer if synced" do
#           filer_new = FactoryBot.create(:filer, account: @account, cloud_resource_adapter: @cloud_resource_adapter, tenant_id: 'old_tenant_id')
#           stub_request(:get, "http://192.168.10.32/occm/api/vsa/working-environments?fields=Status,clusterProperties").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => @sample_filer_response.last.body.to_json , :headers => {})
#           result = Filers::CloudResources::NetAppService.synchronize_filers(filer_new.account_id, @params)
#           expect(filer_new.reload.tenant_id).to eq('Tenant-4RcmUFVx')
#         end

#         it "should and return false if some error occured while fethcing WE" do
#           stub_request(:get, "http://192.168.10.32/occm/api/vsa/working-environments?fields=Status,clusterProperties").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 400, :body => {"error" => "message"} , :headers => {})
#            result = Filers::CloudResources::NetAppService.synchronize_filers(@account_id, @params)
#            expect(result).to eq(false)
#         end

#         it "should return true" do
#           allow(Filers::CloudResources::NetAppWorkers::SynchronizerWorker).to receive(:perform_async).and_return(true)
#            result = Filers::CloudResources::NetAppService.fetch_filers(@account,{:cloud_resource_adapter_ids => ['id']})
#            expect(result).to eq(true)
#         end
#       end

#       describe '#get_parsed_attributes' do
#         it "should return underscorized keys of hashes in the given array" do
#           raw_hash = [{'publicId' => "test",  "tenantId" => 'tenid'}, {'environmentName' => 'test'}].to_json
#           expected_hash = [{'public_id' => "test",  "tenant_id" => 'tenid'}, {'environment_name' => 'test'}]
#           result = Filers::CloudResources::NetAppService.get_parsed_attributes(raw_hash)
#           expect(result).to eq(expected_hash)
#         end
#       end

#       describe "#update_enabled" do
#         it "should update the attribute enabled" do
#           @filer = FactoryBot.create(:filer, account: @account, cloud_resource_adapter: @cloud_resource_adapter)
#           expect(@filer.enabled).to eq(true)
#           Filers::CloudResources::NetAppService.update_enable(@filer, {:enabled =>  false})
#           expect(@filer.reload.enabled).to eq(false)
#         end
#         it "should return nil if could not update the attribute" do
#           @filer = FactoryBot.create(:filer, account: @account, cloud_resource_adapter: @cloud_resource_adapter)
          # Filers::CloudResources::NetAppService.update_enable(@filer)
#           expect(Filers::CloudResources::NetAppService.update_enable(@filer, {})).to eq(nil)
#         end
#       end
#     end
#   end
# end
