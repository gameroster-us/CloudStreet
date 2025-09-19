# require "spec_helper"

# describe TemplateUpdater do
# 	before(:all) do
# 		@user = FactoryBot.create(:user)
#     @template = FactoryBot.create(:template, name: 'hello', description: 'test description')
#   end

# 	describe ".update_template_details" do
# 		it "updates name of the template" do
# 			params = {"name" => "hellotest"}
# 			TemplateUpdater.update_template_details(@template, params, @user)
# 			expect(@template.name).to eq "hellotest"
# 		end

# 		it "updates description of the template" do
# 			params = {"description" => "hello test description"}
# 			TemplateUpdater.update_template_details(@template, params, @user)
# 			expect(@template.description).to eq "hello test description"
# 		end

# 	end
# end
