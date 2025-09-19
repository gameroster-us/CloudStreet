class AddIsTagInsensitiveToGeneralSetting < ActiveRecord::Migration[5.1]

  def change
    add_column :general_settings, :is_tag_case_insensitive, :boolean, default: true
  end

end
