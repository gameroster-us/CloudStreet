class CreateMiraEndpoints < ActiveRecord::Migration[5.2]
  def change
    create_table :mira_endpoints, id: :uuid do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
