class CreateJoinTableOrganisationsUsers < ActiveRecord::Migration[5.1]
  def change
    create_join_table(:organisations, :users, column_options: {type: :uuid})
  end
end
