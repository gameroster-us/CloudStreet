# require "spec_helper"

# describe EnvironmentUpdater do
# 	before(:all) do
# 		@user = FactoryBot.create(:user)
#     @environment = FactoryBot.create(:environment, name: 'hello', description: 'test description')
#   end

# 	describe ".update" do
# 		it "updates name of the environment" do
# 			params = {"name" => "hellotest"}
# 			updated_environment = EnvironmentUpdater.update(@environment, params, @user.id)
# 			expect(updated_environment.name).to eq "hellotest"
# 		end

# 		it "updates description of the environment" do
# 			params = {"description" => "hello test description"}
# 			updated_environment = EnvironmentUpdater.update(@environment, params, @user.id)
# 			expect(updated_environment.description).to eq "hello test description"
# 		end

# 		it "returns validation error if save returns false" do
#       params = {"description" => "hello test description"}
#       allow(@environment).to receive(:save).and_return(false)
#       updated_environment = EnvironmentUpdater.update(@environment, params, @user.id)
#       expect(@environment.errors).not_to be_nil
# 		end
# 	end
# end
