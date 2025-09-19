# require 'spec_helper'

# context "properties present in autoscaling aws representer" do
#   before(:all) do
#     @attrs = FactoryBot.attributes_for(:representer, :autoscaling)
#     @autoscaling = Service.create(@attrs)
#     env = FactoryBot.create(:environment, :running)
#     env.services << @autoscaling
#     @autoscaling.extend(Services::Network::AutoScalingRepresenter::AWSRepresenter)
#     json = @autoscaling.to_json
#     @map = JSON.parse(json)
#   end
#   describe "Check properties non nested" do
#     it "should have property name" do
#       expect(@map['name'] == @attrs[:name]).to eql(true)
#     end
#     it "should have property policies" do
#       expect(@map['policies'] == @attrs[:policies]).to eql(true)
#     end
#     it "should have property default_cooldown" do
#       expect(@map['default_cooldown'] == @attrs[:data]['default_cooldown']).to eql(true)
#     end
#     it "should have property health_check_grace_period" do
#       expect(@map['health_check_grace_period'] == @attrs[:health_check_grace_period]).to eql(true)
#     end
#     it "should have property state" do
#       expect(@map['state'] == @attrs[:state]).to eql(true)
#     end
#   end

#   describe "Check nested properties in details" do
#     it "should have property health_check_type" do
#       expect(@map['health_check_type'] == @attrs[:health_check_type]).to eql(true)
#     end
#     it "should have property desired_capacity" do
#       expect(@map['desired_capacity'] == @attrs[:desired_capacity]).to eql(true)
#     end
#     it "should have property max_size" do
#       expect(@map['max_size'] == @attrs[:max_size]).to eql(true)
#     end
#     it "should have property min_size" do
#       expect(@map['min_size'] == @attrs[:min_size]).to eql(true)
#     end
#   end

#   describe "Check associated or non direct properties" do
#     it "should include property id" do
#       expect(@map).to include 'id'
#     end
#     it "should include load_balancers in details" do
#       expect(@map['details']).to include "load_balancers"
#     end
#     it "should include list_attributes" do
#       expect(@map).to include "list_attributes"
#     end
#     it "should include subnets" do
#       expect(@map).to include "subnets"
#     end
#     it "should include scaling_policies" do
#       expect(@map).to include "scaling_policies"
#     end
#   end
# end
