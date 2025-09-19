class AddFreeTextToServiceNamingDefaults < ActiveRecord::Migration[5.1]
  def change
    add_column :service_naming_defaults, :free_text, :boolean, default: false
  end
end
