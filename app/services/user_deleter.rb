class UserDeleter < CloudStreetService
  def self.delete(user, &block)
    user = fetch User, user

    user.destroy

    yield Status.success
    return
  end
end
