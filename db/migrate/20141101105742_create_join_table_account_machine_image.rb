class CreateJoinTableAccountMachineImage < ActiveRecord::Migration[5.1]
  def change
    create_join_table :accounts, :machine_images do |t|
    	t.uuid :account_id
    	t.uuid :machine_image_id
      t.index [:account_id, :machine_image_id],:unique=>true,:name=>"index_accounts_oses_on_account_id_and_machine_image_id"
    end
  end
end
