class CreateOIDCProviderAuthorizations < ActiveRecord::Migration[5.2]
  def change
    create_table :oidc_provider_authorizations, id: :uuid do |t|
      t.references :account, foreign_key: { to_table: :users }, type: :uuid, null: false
      t.string :client_id, null: false
      t.string :nonce
      t.string :code, null: false
      t.text :scopes, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :oidc_provider_authorizations, :client_id
    add_index :oidc_provider_authorizations, :code, unique: true
  end
end