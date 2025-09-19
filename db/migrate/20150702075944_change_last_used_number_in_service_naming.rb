class ChangeLastUsedNumberInServiceNaming < ActiveRecord::Migration[5.1]
  def change
    change_column :service_naming_defaults, :last_used_number, :string
  end
end
