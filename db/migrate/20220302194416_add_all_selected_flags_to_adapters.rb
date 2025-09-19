class AddAllSelectedFlagsToAdapters < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters, :all_selected_flags, :jsonb, default: {}
  end
end
