# # require 'spec_helper'
# 
# # describe Services::Compute::Server::Azure do
# #   let!(:listner) { FlexibleObjectCreator.new }
# #   let(:subject) do
# #     service = FactoryBot.create(:environmented_service, :server, :azure)
# #     service = Service.find(service.id)
# #     service
# #   end
# #   context "#startup" do
# #     context "when cloud service name is present" do
# #       it "starts virtual machine" do
# #         subject.cloud_service_name = 'server1'
# #         allow(subject).to receive(:start_virtual_machine) {  }
# #         expect(subject).to receive(:start_virtual_machine)
# #         subject.start_virtual_machine
# #       end
# #     end
# #     context "when cloud service name is not present" do
# #       it "creates virtual machine" do
# #         allow(subject).to receive(:provision!) {  }
# #         expect(subject).to receive(:provision)
# #         subject.provision
# #       end
# #     end
# #   end
# 
# #   context "#shutdown" do
# #     it "shutdowns virtual machine" do
# #       subject.cloud_service_name = 'server1'
# #       allow(subject).to receive(:shutdown_virtual_machine) {  }
# #       expect(subject).to receive(:shutdown_virtual_machine)
# #       subject.shutdown_virtual_machine
# #     end
# #   end
# 
# #   context "#reboot_service" do
# #     it "reboots virtual machine" do
# #       subject.cloud_service_name = 'server1'
# #       allow(subject).to receive(:restart_virtual_machine) {  }
# #       expect(subject).to receive(:restart_virtual_machine)
# #       subject.restart_virtual_machine
# #     end
# #   end
# 
# #   context "#terminate_service" do
# #     it "terminates virtual machine" do
# #       subject.cloud_service_name = 'server1'
# #       allow(subject).to receive(:delete_virtual_machine) {  }
# #       expect(subject).to receive(:delete_virtual_machine)
# #       subject.delete_virtual_machine
# #     end
# #   end
# 
# #   # context "#service_actions" do
# #   #   it "with params calls the method passed to it on a connection object" do
# #   #     allow(subject).to receive(:connection_vm) { listner.id= 'testid'; listner }
# #   #     allow(listner).to receive(:send) { listner1.id= 'testid'; listner1 }
# #   #     #expect(listner).to receive(:shutdown_virtual_machine)
# #   #   end
# #   # end
# 
# # end
