class CreateAccountGCPMultiRegions < ActiveRecord::Migration[5.1]
  def change
    create_table :account_gcp_multi_regions, id: :uuid do |t|
      t.belongs_to :account, index: true, foreign_key: true, type: :uuid
      t.belongs_to :gcp_multi_regional, index: true, foreign_key: true, type: :uuid
      t.boolean :enabled
      t.timestamps
    end
  end
end
