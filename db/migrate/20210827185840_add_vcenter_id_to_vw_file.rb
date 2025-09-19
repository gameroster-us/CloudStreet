class AddVcenterIdToVwFile < ActiveRecord::Migration[5.1]
  def change
    add_column :vw_vdc_files, :vw_vcenter_id, :string
  end
end
