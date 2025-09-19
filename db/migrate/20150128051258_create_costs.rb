class CreateCosts < ActiveRecord::Migration[5.1]
  def change
    create_table :costs, id: :uuid do |t|
      t.float :blended_cost
      t.float :unblended_cost
      t.string :availability_zone
      t.string :resource_id, index: true
      t.string :resource_type, index: true
      t.date :date, index: true
      t.string :type, index: true
      t.uuid :service_id, index: true
      t.uuid :environment_id, index: true
      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true

      t.timestamps
    end
  end
end
