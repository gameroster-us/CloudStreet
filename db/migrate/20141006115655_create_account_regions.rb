class CreateAccountRegions < ActiveRecord::Migration[5.1]
  def change
    create_table :account_regions, id: :uuid do |t|
      t.uuid    :account_id, index: true
      t.uuid    :region_id,  index: true
      t.boolean :enabled,    default: true

      t.timestamps
    end
  end
end
