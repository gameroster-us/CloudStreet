class AddActivatedByUserToUsers < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:users, :activated_by_user)
      add_column :users, :activated_by_user, :boolean
    end
  end
end
