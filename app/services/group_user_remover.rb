class GroupUserRemover < CloudStreetService
  attr_reader :member

  def self.remove(group, user, &block)
    group = fetch Group, group
    user = fetch User, user

    if user == group.account.user && group.has_role?(:account_owner, group.account)
      status GroupUserStatus, :member_is_owner, nil, &block
      return nil
    end

    group.remove_user(user)
    group.save!

    status GroupUserStatus, :success, user, &block
  end
end
