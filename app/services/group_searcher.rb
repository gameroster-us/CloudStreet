class GroupSearcher < CloudStreetService
  def self.search(account_id, &block)
    account = fetch Account, account_id

    groups = Group.where(account_id: account.id)

    status Status, :success, groups, &block
    return groups
  end

  def self.find(account, group, &block)
    group = fetch Group, group

    status Status, :success, group, &block
    return group
  end
end