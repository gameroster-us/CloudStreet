class AddSsoKeywordsToTenants < ActiveRecord::Migration[5.1]
  def change
    add_column :tenants, :sso_keywords, :text, array:true, default: []
  end
end
