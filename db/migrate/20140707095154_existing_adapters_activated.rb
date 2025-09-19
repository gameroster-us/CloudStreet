class ExistingAdaptersActivated < ActiveRecord::Migration[5.1]
  def change
    execute "update adapters set state = 'active' where state = 'created';"
  end
end
