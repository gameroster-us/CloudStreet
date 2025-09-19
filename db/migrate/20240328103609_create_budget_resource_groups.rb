class CreateBudgetResourceGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :budget_resource_groups, id: :uuid do |t|
      t.json   :resources, array: true, default: []
      t.boolean :is_resource_group_select_all, default: false
      t.references :budget, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
