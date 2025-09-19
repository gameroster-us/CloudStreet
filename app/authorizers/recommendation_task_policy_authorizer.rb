class RecommendationTaskPolicyAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user, args = {})
    false
  end

  def self.readable_by?(user, args = {})
    user.is_permission_granted?('cs_recommendation_task_policy_view')
  end

  def self.updatable_by?(user, args = {})
    user.is_permission_granted?('cs_recommendation_task_policy_edit')
  end

  def self.creatable_by?(user, args = {})
    user.is_permission_granted?('cs_recommendation_task_policy_add')
  end

  def self.deletable_by?(user)
    user.is_permission_granted?('cs_recommendation_task_policy_delete')
  end
end