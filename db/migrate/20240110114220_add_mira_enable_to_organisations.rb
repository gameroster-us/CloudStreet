class AddMiraEnableToOrganisations < ActiveRecord::Migration[5.2]
  def change
    add_column :organisations, :mira_enable, :boolean, default: false
  end
end
