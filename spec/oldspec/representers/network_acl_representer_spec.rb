# require 'spec_helper'

# describe NetworkAclRepresenter do
#   before(:all) do
#     @attrs = FactoryBot.attributes_for(:nacl_for_representer)
#     @nacl = Nacl.new(@attrs)
#     @nacl.extend(NetworkAclRepresenter)
#     json = @nacl.to_json
#     @map = JSON.parse(json)
#   end

#   describe 'Check properties' do
#     it "should have property name" do
#       expect(@map['name'] == @attrs[:name]).to eql(true)
#     end

#     it "should have property provider_id" do
#       expect(@map['provider_id'] == @attrs[:provider_id]).to eql(true)
#     end

#     it "should have property vpc_id" do
#       expect(@map['vpc_id'] == @attrs[:vpc_id]).to eql(true)
#     end

#     it "should have property provider_vpc_id" do
#       expect(@map['provider_vpc_id'] == @attrs[:provider_vpc_id]).to eql(true)
#     end

#     it "should have property provider_data" do
#       expect(@map['provider_data'] == @attrs[:provider_data]).to eql(true)
#     end

#     it "should have property account_id" do
#       expect(@map['account_id'] == @attrs[:account_id]).to eql(true)
#     end

#     it "should have property adapter_id" do
#       expect(@map['adapter_id'] == @attrs[:adapter_id]).to eql(true)
#     end

#     it "should have property region_id" do
#       expect(@map['region_id'] == @attrs[:region_id]).to eql(true)
#     end

#     it "should have property entries" do
#       expect(@map['entries'] == @attrs[:entries]).to eql(true)
#     end

#     it "should have property tags" do
#       expect(@map['tags'] == @attrs[:tags]).to eql(true)
#     end

#     it "should have property type" do
#       expect(@map['type'] == @attrs[:type]).to eql(true)
#     end

#     it "should have property associations" do
#       expect(@map['associations'] == @attrs[:associations]).to eql(true)
#     end
#   end
# end
