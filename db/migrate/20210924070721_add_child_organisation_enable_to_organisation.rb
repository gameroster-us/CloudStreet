class AddChildOrganisationEnableToOrganisation < ActiveRecord::Migration[5.1]
  def change
    add_column :organisations, :child_organisation_enable, :boolean, default: false
  end
end
