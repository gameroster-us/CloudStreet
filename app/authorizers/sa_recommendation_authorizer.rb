class SaRecommendationAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user, args = {})
    false
  end

  def self.manageable_by?(user,args={})
    user.is_permission_granted?('cs_sa_recommendation_task_history')
  end

  def self.readable_by?(user, args = {})
    user.is_permission_granted?('cs_sa_recommendation_task_view')
  end

  def self.updatable_by?(user, args = {})
    user.is_permission_granted?('cs_sa_recommendation_task_edit')
  end

  def self.creatable_by?(user, args = {})
    user.is_permission_granted?('cs_sa_recommendation_task_create')
  end

  def self.deletable_by?(user)
    user.is_permission_granted?('cs_sa_recommendation_task_delete')
  end
end
