class CreateServiceGroupPolicies < ActiveRecord::Migration[5.1]
  def change
    create_table :service_group_policies, id: :uuid do |t|
      t.string :name, null: false
      t.uuid :account_id, null: false, index: true
      t.uuid :tenant_id, null: false, index: true
      t.uuid :billing_adapter_id, null: false, index: true
      t.string :type, null: false
      t.text :description, null: false
      t.text :state, null: false
      t.jsonb :data, default: {}
      t.jsonb :custom_data, default: {}
      t.datetime :deleted_at, default: nil

      t.timestamps
    end
  end
end
