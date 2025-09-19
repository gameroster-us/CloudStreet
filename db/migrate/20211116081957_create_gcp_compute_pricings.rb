class CreateGCPComputePricings < ActiveRecord::Migration[5.1]
  def change
    create_table :gcp_compute_pricings, id: :uuid do |t|
      t.string :name
      t.string :sku, :unique => true
      t.string :description
      t.string :service_name
      t.string :resource_family
      t.string :resource_group
      t.string :usage_type
      t.jsonb :pricing_info, default: []
      t.text :service_regions, array: true, default: []
      t.timestamps
    end
    add_index :gcp_compute_pricings, [:description, :resource_group, :service_regions], name: "index_gcp_on_description_and_res_gp_and_ser_regions"
  end
end
