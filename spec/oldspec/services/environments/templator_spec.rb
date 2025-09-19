# require "spec_helper"

# describe "environment/Templator" do
  # context ".templatize" do
  #   before(:all) do
  #     account ||= FactoryBot.create(:account)
  #     @template_attrs = { name: 'test-template', account_id: account.id, created_by: account.users.first.id }
  #     @services_count = 2
  #     @environment = FactoryBot.create :environment, :aws_environment, :with_services, number_of_services: @services_count
  #     @return_value = Environments::Templator.templatize @template_attrs, @environment
  #   end

  #   describe "return value" do
  #     subject { @return_value }

  #     it { should be_a(Template) }

  #     it "is persisted in database" do
  #       expect(subject.persisted?).to be true
  #     end

  #     its(:name)              { should eq @template_attrs[:name] }
  #     its(:account_id)        { should eq @template_attrs[:account_id] }
  #     its(:created_by)        { should eq @template_attrs[:created_by] }
  #     its(:template_model)    { should eq @environment.environment_model }
  #     its(:region)            { should eq @environment.region }
  #     its(:adapter)           { should eq @environment.default_adapter }
  #   end

  #   it "copies all nested services" do
  #     expect(Template.first.services.count).to eq @services_count
  #   end
  # end
# end
