class SgReplaceLog
  include Mongoid::Document
  include Mongoid::Timestamps
  field :old_sg, type: String
  field :new_sg, type: String
  field :status, type: String
  field :error, type: String
  field :error_backtrace, type: String
end
