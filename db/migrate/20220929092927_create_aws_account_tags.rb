class CreateAWSAccountTags < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_account_tags, id: :uuid do |t|
      t.uuid :adapter_id, index: true
      t.jsonb :tags, array: true, default: []
      t.string :aws_account_id
      t.timestamps
    end
  end
end
