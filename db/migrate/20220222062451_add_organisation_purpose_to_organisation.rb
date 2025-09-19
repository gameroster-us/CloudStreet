class AddOrganisationPurposeToOrganisation < ActiveRecord::Migration[5.1]
  def change
    add_column :organisations, :organisation_purpose, :string
  end
end
