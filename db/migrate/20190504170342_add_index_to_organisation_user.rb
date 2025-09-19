class AddIndexToOrganisationUser < ActiveRecord::Migration[5.1]
  def change
  	add_index :organisations_users, [ :organisation_id, :user_id ], :unique => true, :name => 'uniq_by_organisation_and_user'
  end
end
