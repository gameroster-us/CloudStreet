# require 'spec_helper'

# describe ServiceTerminator do
#   describe '.terminate!' do
#     before(:each) do
#       @user = FactoryBot.create(:user)
#       @service = FactoryBot.create(:service, :volume_aws, :running, account: @account, region: @sao_paulo_region, adapter: @dev_adapter, environment: @environment, data: '{"size":10,"volume_type":"Magnetic","iops":100,"device":"/dev/sda1","root_device":true,"attach_status":"detached","status":"deleted"}')
#       @environment = FactoryBot.create(:environment, :with_two_servers_removed_from_provider)
#     end

#     it "should always have a user present" do
#       allow(@service).to receive(:environment) { @environment }
#       allow(@service).to receive_message_chain(:adapter, :active?) {true}
#       allow(@service).to receive(:terminated?) { true }
#       ServiceTerminator.terminate!(@service, @user,{})
#       expect(@service.user).not_to be_nil
#     end
#   end
# end
