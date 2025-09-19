class CreateSynchronizationSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :synchronization_settings, id: :uuid  do |t|
			t.uuid :account_id,  index: true
			t.json :repeat
			t.time :sync_time
			t.boolean :auto_sync_to_aws, default: false
			t.boolean :auto_sync_to_cs_from_aws, default: false
			t.timestamps
    end

    Account.all.each do|account|
    	account.synchronization_setting = SynchronizationSetting.create unless account.synchronization_setting
    end
  end
end
