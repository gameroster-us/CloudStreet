# require 'spec_helper'
# 
# describe Resources::KeyPair do
# 	before :all do
# 		keypair = FactoryBot.create(:resource, :key_pair, :with_account, :for_region_sa_east_1)
# 		@keypair = Resource.find(keypair.id)
# 	end
# 
# 	describe '.delete_keypair' do
# 		it 'should delete key pair' do
# 			allow(@keypair).to receive_message_chain('wrapper_agent.destroy').and_return(true)
# 			expect {@keypair.delete_keypair}. to change(Resources::KeyPair, :count).by(-1)
# 		end
# 
# 		it 'should raise error' do
# 			allow(@keypair).to receive_message_chain('wrapper_agent.destroy').and_raise(Fog::Compute::AWS::Error)
# 			expect {@keypair.delete_keypair}. to raise_error
# 		end
# 	end
# end
