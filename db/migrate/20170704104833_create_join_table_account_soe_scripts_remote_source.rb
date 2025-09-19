class CreateJoinTableAccountSoeScriptsRemoteSource < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts_soe_scripts_remote_sources, :id => :uuid do |t|
      t.string :name, not_null: true
      t.uuid :account_id, not_null: true
      t.uuid :soe_scripts_remote_source_id, not_null: true
      t.foreign_key :accounts, :null => false, on_delete: :cascade, name: 'acc_soe_script_source_acc_id_fk'
      t.foreign_key :soe_scripts_remote_sources, :null => false, on_delete: :cascade, name: 'source_soe_script_source_acc_id_fk'
    end
  end
end
