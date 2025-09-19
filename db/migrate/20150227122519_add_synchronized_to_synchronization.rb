class AddSynchronizedToSynchronization < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronizations, :synchronized, :boolean, default: false
  end
end
