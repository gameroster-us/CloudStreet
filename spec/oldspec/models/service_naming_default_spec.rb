# require 'spec_helper'
# 
# describe ServiceNamingDefault do
#   context 'associations' do
#     it { should belong_to(:account) }
#   end
# 
#   context 'validations' do
#     describe 'if naming convention enabled' do
#       before { allow(subject).to receive(:naming_convention_enabled?).and_return(true) }
#       it { should allow_value('name##').for(:prefix_service_name) }
#       it { should validate_presence_of(:suffix_service_count) }
#     end
#     describe 'if naming convention not enabled' do
#       before { allow(subject).to receive(:naming_convention_enabled?).and_return(false) }
#       it { should_not validate_presence_of(:prefix_service_name) }
#       it { should_not validate_presence_of(:suffix_service_count) }
#     end
# 
#     describe 'after present validation' do
#       before { allow(subject).to receive(:naming_convention_enabled?).and_return(true) }
#       describe 'invalid cases' do
#         it "requires the prefix_service_name to have no other special chars except '-'" do
#           subject.prefix_service_name = 'Invalid-name_$'
#           expect(subject).to_not be_valid
#         end
#         it 'requires the suffix service count not to have except numbers' do
#           subject.suffix_service_count = 'non_number'
#           expect(subject).to_not be_valid
#         end       
#       end     
#       describe 'valid cases' do
#         it 'passes when all attributes is given valid' do
#           subject.prefix_service_name = 'valid-name##'
#           subject.suffix_service_count = 1        
#           expect(subject).to be_valid
#         end        
#       end 
#     end
#   end
# 
#   describe '#prefix_service_name_regexp' do
#     subject { ServiceNamingDefault.new(prefix_service_name: 'some_name').prefix_service_name_regexp(nil) }
#     it { is_expected.to be_kind_of Regexp }
#     it { is_expected.to eq(/\A(#{Regexp.quote('some_name')})\z/) }
#   end
# end
