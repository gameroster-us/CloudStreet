class StorageVm < ApplicationRecord
  include Filterable
  belongs_to :filer

  scope :filer_id, ->(filer_ids) { where(filer_id: filer_ids) }

  # validates :mount_ip, presence:true, :unless => Proc.new {
  #   self.filer.working_environment_type.eql?("VSA") && self.filer.data["is_ha"].eql?(true)
  # }
end