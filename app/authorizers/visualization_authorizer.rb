class VisualizationAuthorizer < ApplicationAuthorizer
  def self.default(_user)
    false
  end

  def self.visualizable_by?(user)
    user.is_permission_granted?("cs_environment_visualization")
  end
end
