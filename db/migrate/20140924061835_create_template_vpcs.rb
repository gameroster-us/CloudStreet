class CreateTemplateVpcs < ActiveRecord::Migration[5.1]
  def change
    create_table :template_vpcs , id: :uuid  do |t|
      t.uuid :template_id, index: true
      t.uuid :vpc_id, index: true	

      t.timestamps
    end
  end
end
