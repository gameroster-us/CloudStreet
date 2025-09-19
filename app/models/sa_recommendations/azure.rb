# frozen_string_literal: true

module SaRecommendations
  class Azure < SaRecommendation
    class << self
      def model_name
        SaRecommendation.model_name
      end
    end
  end
end
