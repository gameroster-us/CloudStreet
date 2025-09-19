class MoveCollaboratorsOutOfOwnerGroup < ActiveRecord::Migration[5.1]
  def change
    Account.all.each do |account|
      owners_group = account.owners_group
      if owners_group.users.length > 1
        members_group = account.groups.where(name: "read only").first_or_create!
        owners_group.users.each do |user|
          # Username will match account name if they own it
          if user.username != account.name
            owners_group.remove_user(user)
            members_group.add_user(user)
          end
        end
      end
    end
  end
end
