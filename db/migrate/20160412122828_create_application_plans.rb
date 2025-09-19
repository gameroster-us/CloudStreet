class CreateApplicationPlans < ActiveRecord::Migration[5.1]
  def change
    create_table :application_plans, id: :uuid do |t|
      t.string :name
      t.string :description
      t.numrange :max_usage_allowed
      t.decimal :cost_percentage, precision: 2
      t.string :support_type
    	t.integer :trial_period_days

      t.timestamps
    end
  end  
end
