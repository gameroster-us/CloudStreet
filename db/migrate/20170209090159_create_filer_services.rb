class CreateFilerServices < ActiveRecord::Migration[5.1]
  def change
    create_table :filer_services, id: :uuid do |t|
      t.uuid :filer_id
      t.uuid :service_id
      t.timestamps
    end
  end
end
