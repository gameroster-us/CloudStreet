class CreateTemplateCosts < ActiveRecord::Migration[5.1]
  def change
    create_table :template_costs, id: :uuid do |t|
      t.uuid :region_id
      t.json :data
      t.string :type

      t.timestamps
    end
  end
end
