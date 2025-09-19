class RouteTableAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    return unless resource.try(:account_id)
    user.account_id == resource.account_id
  end

  def updatable_by?(user)
    return unless resource.try(:account_id)
    user.account_id == resource.account_id
  end

  def deletable_by?(user)
    return unless resource.try(:account_id)
    user.account_id == resource.account_id
  end
end
