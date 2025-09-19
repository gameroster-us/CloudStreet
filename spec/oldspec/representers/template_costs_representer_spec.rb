# require 'spec_helper'

# describe TemplateCostsRepresenter do
#   before(:all) do
#     @account ||= FactoryBot.create(:account, :with_user)
#     @template_costs = FactoryBot.create(:template_cost, type: 'TemplateCosts::AWS')
#     @template_costs.extend(TemplateCostsRepresenter)
#     @represented_hash = @template_costs.to_hash(current_user: @account.users.first)
#   end

#   describe 'represented hash' do
#     it { expect(@represented_hash['id']).to eq(@template_costs.id) }
#     it { expect(@represented_hash['region_id']).to eq(@template_costs.region_id) }
#     it { expect(@represented_hash['data']).to eq(@template_costs.data) }
#     it { expect(@represented_hash['type']).to eq(@template_costs.type) }
#   end
# end
