class CreateServiceManagerSummaries < ActiveRecord::Migration[5.2]
  def change
    create_table :service_manager_summaries, id: :uuid do |t|
      t.references :account, type: :uuid, foreign_key: true
      t.references :tenant, type: :uuid, foreign_key: true
      t.json :summary_data
      t.timestamps
    end
    # add index for both foreign key
  end
end
