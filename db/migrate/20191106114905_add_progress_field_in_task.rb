class AddProgressFieldInTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :progress, :json, null: false, :default => { total: 0,success: 0, failure: 0 }
  end
end
