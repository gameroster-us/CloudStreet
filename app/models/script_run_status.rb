class ScriptRunStatus
  include Mongoid::Document
  field :script_type, type: String
  field :run_status, type: Mongoid::Boolean
end
