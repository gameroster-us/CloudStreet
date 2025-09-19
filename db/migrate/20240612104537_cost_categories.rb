class CostCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :cost_categories, id: :uuid do |t|
      t.references :adapter, type: :uuid, foreign_key: true
      t.string :display_name
      t.string :category_name
      t.string :type
      t.json :category_value, array: true, default: []
      t.timestamps
    end
  end
end
