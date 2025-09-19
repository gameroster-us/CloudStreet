class AddDistributorAccessToOrganisation < ActiveRecord::Migration[5.1]
  def change
    add_column :organisations, :distributor_access, :integer
  end
end
