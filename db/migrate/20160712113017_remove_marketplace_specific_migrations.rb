class RemoveMarketplaceSpecificMigrations < ActiveRecord::Migration[5.1]
  def change
    unless column_exists? :organisations, :trial_period_days
      add_column :organisations, :trial_period_days, :integer, default: 0
    end

    unless column_exists? :organisations, :application_plan_id
      add_column :organisations, :application_plan_id, :uuid
    end

    unless table_exists? :application_plans
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
end
