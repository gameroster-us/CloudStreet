class AddUserToOrganisation < ActiveRecord::Migration[5.1]
  def change
    add_reference :organisations, :user, type: :uuid, foreign_key: true
  end
end
