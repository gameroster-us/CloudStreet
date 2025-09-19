class CreateSsoConfigs < ActiveRecord::Migration[5.1]
  def change
    create_table :sso_configs do |t|
      t.text :idp_sso_target_url
      t.text :idp_slo_target_url
      t.text :idp_entity_id
      t.text :certificate
      t.uuid :account_id
      t.boolean :disable

      t.timestamps
    end
  end
end
