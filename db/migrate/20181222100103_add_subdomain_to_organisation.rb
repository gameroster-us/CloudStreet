class AddSubdomainToOrganisation < ActiveRecord::Migration[5.1]
  def change
  	add_column :organisations, :subdomain, :string
  end
end
