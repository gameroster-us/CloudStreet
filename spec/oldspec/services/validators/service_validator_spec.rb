# Should be done by mocking, will consider later
# require "spec_helper"

# describe Validators::ServiceValidator do
#   before(:all) do
#     @account = FactoryBot.create(:account, :with_naming_conventions)
#     @account.create_general_setting(naming_convention_enabled: true)
#     @account.service_naming_defaults << FactoryBot.create(:service_naming_default, account: @account)
#     @template = FactoryBot.build(:template).tap do |template|
#       template.account = @account
#       template.adapter = FactoryBot.create(:adapter, :aws)
#     end
#   end

#   context "is_default_name_not_valid?" do
#     describe "when naming convention is enabled for the user" do
#       xit "should return true when invalid" do
#         params = {"services" => [{ "name1" => "SomeString00" }]}
#         template_validator = Validators::TemplateValidator.new params, @account, event: :template_updation
#         expect(template_validator.is_default_name_not_valid?).to_return true
#       end

#       xit "should return false when valid" do
#         params = {"services" => [{ "name1" => "SomeString001" }]}
#         template_validator = Validators::TemplateValidator.new params, @account, event: :template_updation
#         expect(template_validator.is_default_name_not_valid?).to_return false
#       end
#     end

#     describe "when naming convention is not enabled for the user" do

#       before(:each) do
#         # allow(Validator).to receive(:initialize).and_return("")
#         # stub_service_class_call(Validators::TemplateValidator, method: :initialize, response: self)
#       end

#       it "should return nil" do
#         params = {"services" => [@template.attributes]}
#         CSLogger.info "=====template--------#{params.inspect}"
#         template_validator = Validators::TemplateValidator.new params, @account, {event: :template_updation, validating_obj: FactoryBot.create(:environmented_service, :aws)}
#         @account.general_setting.first.update_attributes(naming_convention_enabled: false)
#         expect(template_validator.is_default_name_not_valid?).to_return nil
#       end
#     end
#   end
# end
