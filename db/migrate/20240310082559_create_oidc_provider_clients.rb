class CreateOIDCProviderClients < ActiveRecord::Migration[5.2]
  def change
    create_table :oidc_provider_clients, id: :uuid do |t|
      t.references :organisation, foreign_key: true, type: :uuid
      t.string :identifier
      t.string :secret
      t.string :redirect_uri
      t.string :name

      t.timestamps
    end
  end
end
