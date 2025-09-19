class EnvironmentCSService < ApplicationRecord
  belongs_to :environment
  belongs_to :CS_service
end