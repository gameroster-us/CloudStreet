class RecommendationPolicyCriterium < ApplicationRecord

  belongs_to :recommendation_task_policy


  #Validations
  
  validates :service_type,:service_category,:criteria, presence: true

end
