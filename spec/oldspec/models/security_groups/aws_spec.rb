# require 'spec_helper'
# 
# describe SecurityGroups::AWS do
#   describe '#format_attributes_by_raw_data' do
#     @keys = [
#       :name, :description, :group_id, :owner_id, :ip_permissions, :ip_permissions_egress
#     ]
#     @aws_service = FactoryBot.build(:fog_security_group)
#     it_behaves_like "aws_attribute_formater", @aws_service, @keys
#   end
# 
#   it_behaves_like "data_store_common_attribute_mapper"
# end
