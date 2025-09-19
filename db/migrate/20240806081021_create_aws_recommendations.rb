class CreateAWSRecommendations < ActiveRecord::Migration[5.2]
  def change
    create_table :aws_recommendations, id: :uuid do |t|
      t.uuid :billing_adapter_id
      t.string :aws_account_id
      t.float :potential_benifit, default: 0.0
      t.string :type

      t.timestamps
    end
    add_index :aws_recommendations, :billing_adapter_id
  end
end
