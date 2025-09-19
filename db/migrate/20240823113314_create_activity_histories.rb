class CreateActivityHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :activity_histories, id: :uuid do |t|
      t.references :trackable, polymorphic: true
      t.json :details

      t.timestamps
    end
  end
end
