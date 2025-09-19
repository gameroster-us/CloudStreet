# require 'spec_helper'
# 
# describe Services::Vpc do
#   before(:all) do
#     @test_account = FactoryBot.create(:account)
#     @test_accnt_adapter = FactoryBot.create(:adapter, :aws, account: @test_account)
# 
#     @test_vpc = FactoryBot.create(:vpc, account: @test_account, vpc_id: 'vpc_123dsd', adapter: @test_accnt_adapter)
#     @test_service_vpc = FactoryBot.create(:service, :vpc, account: @test_account, adapter: @test_accnt_adapter, data: {vpc_id: @test_vpc.vpc_id})
#     @test_service_vpc = Service.find(@test_service_vpc.id)
# 
#     @test_accnt_another_adapter = FactoryBot.create(:adapter, :aws, account: @test_account)
#     @test_another_vpc = FactoryBot.create(:vpc, account: @test_account, vpc_id: 'vpc_456sas', adapter:@test_accnt_another_adapter)
#     @test_service_another_vpc = FactoryBot.create(:service, :vpc, account: @test_account, adapter:@test_accnt_another_adapter, data: {vpc_id: @test_another_vpc.vpc_id})
#     @test_service_another_vpc = Service.find(@test_service_another_vpc.id)
# 
#     @new_account = FactoryBot.create(:account)
#     @new_accnt_adapter = FactoryBot.create(:adapter, :aws, account: @new_account)
# 
#     @new_vpc = FactoryBot.create(:vpc, account: @new_account, vpc_id: 'vpc_123dsd', adapter:@new_accnt_adapter)
#     @new_service_vpc = FactoryBot.create(:service, :vpc, account: @new_account, adapter:@new_accnt_adapter, data: {vpc_id: @new_vpc.vpc_id})
#     @new_service_vpc = Service.find(@new_service_vpc.id)
# 
#     Fog.mock!
#     agent = Fog::Compute.new({
#      :provider => 'AWS',
#      :aws_access_key_id => 'ACCESS_KEY_ID',
#      :aws_secret_access_key => 'SECRET_ACCESS_KEY'
#     })
#     @remote_vpc = agent.vpcs.create(cidr_block: '10.0.0.0/24')
#   end
# 
#   describe ".fetch_additional_data" do
#     it "should return hash with key enable_dns_hostnames" do
#       expect(Services::Vpc.fetch_additional_data(@remote_vpc)).to have_key(:enable_dns_hostnames)
#     end
# 
#     it "should return hash with key enable_dns_resolution" do
#       expect(Services::Vpc.fetch_additional_data(@remote_vpc)).to have_key(:enable_dns_resolution)
#     end
#   end
#   describe "#get_vpc" do
#     it "should not return vpc of another account" do
#       expect(@test_service_vpc.get_vpc.account_id).not_to eql(@new_account.id)
#     end
# 
#     it "should not return vpc of different adapter of same account" do
#       expect(@test_service_vpc.get_vpc.adapter_id).not_to eql(@test_accnt_another_adapter)
#     end
# 
#     it "should not return valid vpc" do
#       expect(@new_service_vpc.get_vpc).to eql(@new_vpc)
#     end
#   end
# 
#   describe '#absolute_geometry' do
#     context 'when internet connected' do
#       before(:each) { allow(@test_service_vpc).to receive(:internet_connected_vpc?) { true } }
# 
#       it 'returns Hash' do
#         expect(@test_service_vpc.absolute_geometry).to be_kind_of(Hash)
#       end
# 
#       describe 'x key' do
#         it 'is integer' do
#           expect(@test_service_vpc.absolute_geometry['x']).to be_kind_of(Integer)
#         end
# 
#         it 'is valued 30' do
#           expect(@test_service_vpc.absolute_geometry['x']).to eq(30)
#         end
#       end
# 
#       describe 'y key' do
#         it 'is integer' do
#           expect(@test_service_vpc.absolute_geometry['y']).to be_kind_of(Integer)
#         end
# 
#         it 'is valued 2' do
#           expect(@test_service_vpc.absolute_geometry['y']).to eq(2)
#         end
#       end
#     end
# 
#     context 'when not internet connected' do
#       before(:each) { allow(@test_service_vpc).to receive(:internet_connected_vpc?) { false } }
# 
#       it 'returns Hash' do
#         expect(@test_service_vpc.absolute_geometry).to be_kind_of(Hash)
#       end
# 
#       describe 'x key' do
#         it 'is integer' do
#           expect(@test_service_vpc.absolute_geometry['x']).to be_kind_of(Integer)
#         end
# 
#         it 'is valued 30' do
#           expect(@test_service_vpc.absolute_geometry['x']).to eq(2)
#         end
#       end
# 
#       describe 'y key' do
#         it 'is integer' do
#           expect(@test_service_vpc.absolute_geometry['y']).to be_kind_of(Integer)
#         end
# 
#         it 'is valued 2' do
#           expect(@test_service_vpc.absolute_geometry['y']).to eq(2)
#         end
#       end
#     end
#   end
# end
