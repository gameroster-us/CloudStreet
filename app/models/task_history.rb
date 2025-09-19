class TaskHistory < ApplicationRecord
  validates :user_id, :sa_recommendation_id, :state, :comment, :presence => true

  belongs_to :sa_recommendation
end
