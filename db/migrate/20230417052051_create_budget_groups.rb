class CreateBudgetGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :budget_groups, id: :uuid do |t|
      t.uuid :group_id
      t.string :group_name
      t.references :budget, type: :uuid, foreign_key: true
      t.timestamps
    end
  end
end
