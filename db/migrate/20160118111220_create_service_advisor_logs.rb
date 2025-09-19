class CreateServiceAdvisorLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :service_advisor_logs, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :account_id
      t.uuid :service_id
      t.hstore :data
      t.uuid :origin_environment_id
      t.uuid :destination_environment_id
      t.string :event_type
      t.string :status
      t.timestamps
    end
  end
end
