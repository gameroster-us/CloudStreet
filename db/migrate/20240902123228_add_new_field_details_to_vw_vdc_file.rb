class AddNewFieldDetailsToVwVdcFile < ActiveRecord::Migration[5.2]
  def change
    add_column :vw_vdc_files, :additional_details, :jsonb, default: {}
  end
end
