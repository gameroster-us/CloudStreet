class AddEnabledToFilers < ActiveRecord::Migration[5.1]
  def change
    add_column :filers, :enabled, :boolean, default: true
  end
end
