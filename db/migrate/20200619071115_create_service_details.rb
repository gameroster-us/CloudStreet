class CreateServiceDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :service_details, id: :uuid do |t|
      t.string :ignored_from
      t.string :ignored_from_category
      t.string :ignored_comment
      t.string :ignored_by
      t.datetime :ignored_date
      t.string :comment
      t.string :commented_by
      t.datetime :commented_date
      t.uuid :adapter_id
      t.uuid :region_id
      t.string :provider_id

      t.timestamps
    end
  end
end
