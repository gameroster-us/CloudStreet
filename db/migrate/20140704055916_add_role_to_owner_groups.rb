class AddRoleToOwnerGroups < ActiveRecord::Migration[5.1]
  def change
    Account.all.each do |account|
      account.owners_group.add_role :account_owner, account
    end
  end
end
