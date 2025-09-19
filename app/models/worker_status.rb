class WorkerStatus
  include Mongoid::Document
  field :name, type: String
  field :status, type: Mongoid::Boolean
end
