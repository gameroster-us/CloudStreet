class CreateServiceGroupCosts < ActiveRecord::Migration[5.2]
  def change
    create_table :service_group_costs, id: :uuid do |t|
      t.float 'service_adviser_pf', default: 0.0
      t.float 'ri_pf', default: 0.0
      t.string 'ri_currency', default: 'USD'
      t.float 'sp_pf', default: 0.0
      t.string 'sp_currency', default: 'USD'
      t.json 'current_month_spend', default: { :unblended => 0.0, :net_amortized_cost => 0.0, :customer_cost => 0.0, :net_cost => 0.0, :reseller_org_net_cost => 0.0, :amortized => 0.0, :cost => 0.0 }
      t.string 'current_month_spend_currency', default: 'USD'
      t.string 'service_group_name'
      t.string 'provider_type'
      t.references 'service_group', type: :uuid, foreign_key: true, index: true
      t.references 'tenant', type: :uuid, foreign_key: true, index: true
      t.timestamps
    end
  end
end
