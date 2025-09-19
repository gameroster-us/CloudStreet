class EnvironmentStorage < ApplicationRecord

	belongs_to :environment
	belongs_to :storage

	validates :environment_id, :uniqueness => {:scope => :storage_id}
end