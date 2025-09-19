class AddRevisionToTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :revision, :float, default: 0.00, null: false
  end
end
