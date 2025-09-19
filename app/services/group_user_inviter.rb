class GroupUserInviter < CloudStreetService
  def self.invite(group, email, &block)
    user = UserCreator.create_for_invite(email)
    group = fetch Group, group

    group.add_user(user)
    group.save!

    Notification.get_notifier.invite_group_user(user.id)

    # If they're in an admin group make sure we send them the t+c email
    if group.has_role?(:account_owner, group.account) || group.has_role?(:account_admin, group.account)
      Notification.get_notifier.granted_admin_role(user.id, group.account.id)
    end

    status Status, :success, group, &block
    return group
  end
end
