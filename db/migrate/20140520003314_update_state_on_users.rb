class UpdateStateOnUsers < ActiveRecord::Migration[5.1]
  def change
    execute "update users set state = 'active';"
  end
end
