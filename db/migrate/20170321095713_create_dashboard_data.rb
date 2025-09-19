class CreateDashboardData < ActiveRecord::Migration[5.1]
  def change
    create_table :dashboard_data, :id => :uuid do |t|
      t.uuid :account_id, index: true
      t.string :name
      t.json :data

      t.timestamps
    end
  end
end
