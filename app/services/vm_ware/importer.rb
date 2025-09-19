# frozen_string_literal: true

# vmware resource importer
module VmWare
  class Importer
    def self.call(vmware_resources)
      VwInventory.import vmware_resources, on_duplicate_key_update: { conflict_target: [:id], columns: [:cost_by_hour]}
    end
  end
end

