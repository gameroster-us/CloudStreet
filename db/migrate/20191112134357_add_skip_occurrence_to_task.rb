class AddSkipOccurrenceToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :skip_occurrence, :string, array: true, default: []
  end
end
