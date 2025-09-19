class CreateSynchronizationLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :synchronizations,id: :uuid do |t|
      t.string :friendly_id
      t.datetime :started_at
      t.datetime :completed_at
      t.json :state_info
      t.uuid :account_id, index: true
      t.timestamps
    end
  end
end
