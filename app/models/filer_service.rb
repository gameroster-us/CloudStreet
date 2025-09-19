class FilerService < ApplicationRecord
  include Behaviors::BulkInsert  
  validates_presence_of :filer_id, :service_id
  
  belongs_to :filer
  belongs_to :service
end
