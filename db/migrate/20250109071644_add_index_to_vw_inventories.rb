class AddIndexToVwInventories < ActiveRecord::Migration[5.2]
  def change
    execute <<-SQL
      CREATE INDEX index_vw_inventories_vcenter_id_covering
      ON vw_inventories(vw_vcenter_id ASC NULLS LAST, provider_id ASC NULLS LAST, id ASC);
    SQL
  end
end
