class AddScheduleAndIgnoreTillToServiceDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :service_details, :schedule, :text
    add_column :service_details, :ignore_for_days, :string, default: 'forever'
  end
end
