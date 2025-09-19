class InstancePlanner < ApplicationRecord

  store_accessor :data
  
  belongs_to :region
  belongs_to :adapter
  belongs_to :account
  
end