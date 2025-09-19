class AddActualProtocolToFilerVolumes < ActiveRecord::Migration[5.1]
  def change
    add_column :filer_volumes, :actual_protocol, :string
  end
end
