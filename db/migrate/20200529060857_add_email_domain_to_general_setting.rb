class AddEmailDomainToGeneralSetting < ActiveRecord::Migration[5.1]
  def change
    add_column :general_settings, :email_domain, :string
  end
end
