# require "spec_helper"

# describe Validators::Services::Compute::Volume::AWS do
#   describe '.get_device_path_regexp' do
#     before(:all) { @server = Service.create(FactoryBot.attributes_for(:service, :server_aws)) }

#     it 'returns REGEXP' do
#       return_value = Validators::Services::Compute::Volume::AWS.get_device_path_regexp(@server)
#       expect(return_value).to be_a Regexp
#     end

#     context 'when server is windows ebs backed' do
#       it 'return valid REGEXP' do
#         @server.platform = 'windows'
#         @server.root_device_type = 'ebs'
#         return_value = Validators::Services::Compute::Volume::AWS.get_device_path_regexp(@server)
#         expect(return_value).to eq(/^\/dev\/xvd[f-p]$/)
#       end
#     end

#     context 'when server is non windows' do
#       before(:all) { @server.platform = 'linux' }

#       context 'when ebs backed' do
#         before(:all) { @server.root_device_type = 'ebs' }

#         context 'when hvm' do
#           before(:all) { @server.virtualization_type = 'hvm' }

#           it 'return valid REGEXP' do
#             return_value = Validators::Services::Compute::Volume::AWS.get_device_path_regexp(@server)
#             expect(return_value).to eq(/^\/dev\/sd[f-p]$/)
#           end
#         end

#         context 'when not hvm' do
#           before(:all) { @server.virtualization_type = 'paravirtual' }

#           it 'return valid REGEXP' do
#             return_value = Validators::Services::Compute::Volume::AWS.get_device_path_regexp(@server)
#             expect(return_value).to eq(/^\/dev\/sd[f-p][1-6]?$/)
#           end
#         end
#       end

#       context 'when non ebs backed' do
#         before(:all) { @server.root_device_type = 'instance-store' }

#         context 'when hvm' do
#           before(:all) { @server.virtualization_type = 'hvm' }

#           context 'when hs1.8xlarge' do
#             before(:all) { @server.flavor_id = 'hs1.8xlarge' }
#             it 'return valid REGEXP' do
#               return_value = Validators::Services::Compute::Volume::AWS.get_device_path_regexp(@server)
#               expect(return_value).to eq(/^\/dev\/sd[b-y]$/)
#             end
#           end

#           context 'when not hs1.8xlarge' do
#             before(:all) { @server.flavor_id = 't1.micro' }
#             it 'return valid REGEXP' do
#               return_value = Validators::Services::Compute::Volume::AWS.get_device_path_regexp(@server)
#               expect(return_value).to eq(/^\/dev\/sd[b-e]$/)
#             end
#           end
#         end

#         context 'when not hvm' do
#           before(:all) { @server.virtualization_type = 'paravirtual' }

#           it 'return valid REGEXP' do
#             return_value = Validators::Services::Compute::Volume::AWS.get_device_path_regexp(@server)
#             expect(return_value).to eq(/^\/dev\/sd[b-e]$/)
#           end
#         end
#       end
#     end
#   end
# end
