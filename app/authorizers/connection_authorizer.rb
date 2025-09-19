class ConnectionAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    user.can_read? resource.interface
  end

  def updatable_by?(user)
    user.can_update? resource.interface
  end

  def deletable_by?(user)
    user.can_delete? resource.interface
  end
end
