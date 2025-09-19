class CreateCustomDashboards < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_dashboards, id: :uuid do |t|
      t.string :name
      t.integer :dashboardHeight
      t.string :type
      t.text :widgets
      t.references :organisation, type: :uuid, foreign_key: true

      t.timestamps
    end
    add_index :custom_dashboards, :name
  end
end
