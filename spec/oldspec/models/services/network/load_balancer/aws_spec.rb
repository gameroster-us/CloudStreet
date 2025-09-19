# require 'spec_helper'
# 
# describe Services::Network::LoadBalancer::AWS do
# 
#   describe '#format_attributes_by_raw_data' do
#     @keys = [ :name, :scheme, :dns_name, :hcheck_interval, :response_timeout, :healthy_threshold, :unhealthy_threshold, :ping_protocol, :ping_protocol_port, :ping_path, :state, :listeners ]
#     @aws_service = FactoryBot.build(:fog_elb)
#     it_behaves_like "aws_attribute_formater", @aws_service, @keys
#   end
# 
# 
#   describe '#set_instance_health' do
#   	it 'sets the instance_health attribute for a lb service w.r.t the remote lb' do
#   		@aws_service = FactoryBot.build(:fog_elb)
#   		load_balancer = FactoryBot.create(:service, :load_balancer, :load_balancer_aws, :running, :aws)
#   		lb  = Service.find load_balancer.id
#   		allow(@aws_service).to receive(:wait_for).and_return({})
#   		lb.set_instance_health(@aws_service, "Instance registration is still in progress.")
#   		expect(lb.instance_health[0]).to eq({"Description"=>"Instance has failed at least the UnhealthyThreshold number of health checks consecutively.", "InstanceId"=>"i-0effc71b", "ReasonCode"=>"Instance", "State"=>"OutOfService"})
#   	end
#   end
# 
# end
