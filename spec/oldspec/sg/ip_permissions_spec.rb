# require 'spec_helper'

# describe ProviderData::Sg::IpPermissions do

# 	describe '#get_ip_permission_array' do
# 		it "should return array of hash with a hash representing CIDR data with group key having a blank value" do
# 			ip_permission = {"groups"=>[{"userId"=>"850388004406", "groupId"=>"sg-4e5a782a"}], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}
# 			key = 'ipRanges'
# 			blank_value_key = 'groups'
# 			result_arr = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}]
#  			expect(ProviderData::Sg::IpPermissions.new([ip_permission]).get_ip_permission_array(ip_permission, key, blank_value_key, [])).to eq(result_arr) 
# 		end

# 		it "should return array of hash representing SG and CIDR data" do 
# 			ip_permission = {"groups"=>[{"userId"=>"850388004406", "groupId"=>"sg-4e5a782a"}], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}
# 			key = 'groups'
# 			blank_value_key = 'ipRanges'
# 			prev_arr = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}]
# 			result_arr = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}, {"groups"=>[{"userId"=>"850388004406", "groupId"=>"sg-4e5a782a"}], "ipRanges"=>[], "ipProtocol"=>"-1"}]
# 			expect(ProviderData::Sg::IpPermissions.new([ip_permission]).get_ip_permission_array(ip_permission, key, blank_value_key, prev_arr)).to eq(result_arr) 
# 		end
# 	end

# 	describe '#extended' do
# 		it "result should have CIDR rule in ipRanges" do
# 			ip_permissions = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}]
# 			result_arr = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}]
# 			expect(ProviderData::Sg::IpPermissions.new(ip_permissions).extended).to eq(result_arr)
# 		end

# 		it "result should have separate hashes for separate CIDR rules" do 
# 			ip_permissions = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}, {"cidrIp"=>"0.0.0.0/16"}], "ipProtocol"=>"-1"}]
# 			result_arr = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}, {"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/16"}], "ipProtocol"=>"-1"}]
# 			expect(ProviderData::Sg::IpPermissions.new(ip_permissions).extended).to eq(result_arr)
# 		end

# 		it "result should have separate hashes for SG and CIDR rules" do 
# 			ip_permissions = [{"groups"=>[{"userId"=>"850388004406", "groupId"=>"sg-4e5a782a"}], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}]
# 			result_arr = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}, {"groups"=>[{"userId"=>"850388004406", "groupId"=>"sg-4e5a782a"}], "ipRanges"=>[], "ipProtocol"=>"-1"}]
# 			expect(ProviderData::Sg::IpPermissions.new(ip_permissions).extended).to eq(result_arr)
# 		end

# 		it "result should have hash for UDP rule" do
# 			ip_permissions = [{"groups"=>[{"userId"=>"850388004406", "groupId"=>"sg-4e5a782a"}], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}, {"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/16"}], "ipProtocol"=>"udp", "fromPort"=>25, "toPort"=>25}]
# 			result_arr = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/8"}], "ipProtocol"=>"-1"}, {"groups"=>[{"userId"=>"850388004406", "groupId"=>"sg-4e5a782a"}], "ipRanges"=>[], "ipProtocol"=>"-1"}, {"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/16"}], "ipProtocol"=>"udp", "fromPort"=>25, "toPort"=>25}]
# 			expect(ProviderData::Sg::IpPermissions.new(ip_permissions).extended).to eq(result_arr)
# 		end


# 		it "result should have hash for TCP rule" do
# 			ip_permissions = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/32"}], "ipProtocol"=>"tcp", "fromPort"=>25, "toPort"=>25}]
# 			result_arr = [{"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/32"}], "ipProtocol"=>"tcp", "fromPort"=>25, "toPort"=>25}]
# 			expect(ProviderData::Sg::IpPermissions.new(ip_permissions).extended).to eq(result_arr)
# 		end
# 	end
# end