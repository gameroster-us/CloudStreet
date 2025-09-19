class RemoveIndexFromAccountMachineImage < ActiveRecord::Migration[5.1]
  def change
  	remove_index :organisation_images,:name=>"index_accounts_oses_on_account_id_and_machine_image_id", column: [:account_id, :machine_image_id]
  end
end
