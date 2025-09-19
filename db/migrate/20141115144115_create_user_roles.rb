class CreateUserRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :user_roles, id: :uuid  do |t|
      t.string :name
      t.uuid :organisation_id, index: true
      t.timestamps
    end
  end
end
