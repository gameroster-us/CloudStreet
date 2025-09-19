class CreateAWSMonthlyTotalCosts < ActiveRecord::Migration[5.2]
  def change
    create_table :aws_monthly_total_costs, id: :uuid do |t|
      t.uuid   :adapter_id
      t.uuid   :tenant_id
      t.string :month
      t.json   :cost, default: {}
      t.timestamps
    end
  end
end
