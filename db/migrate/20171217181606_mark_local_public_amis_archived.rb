class MarkLocalPublicAmisArchived < ActiveRecord::Migration[5.1]
  def up
    MachineImage.where(is_public: true).update_all(active: false)
  end
end
