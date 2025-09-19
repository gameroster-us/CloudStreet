class CreateGCPMultiRegionals < ActiveRecord::Migration[5.1]
  def change
    create_table :gcp_multi_regionals, id: :uuid do |t|
      t.string :name
      t.string :code
      t.uuid :adapter_id, index: true
      t.timestamps
    end
    add_index :gcp_multi_regionals, [:id, :code], name: "index_gcp_multi_regionals_on_id_and_code"
  end
end