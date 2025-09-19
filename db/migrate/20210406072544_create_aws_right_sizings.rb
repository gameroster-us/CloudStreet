class CreateAWSRightSizings < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_right_sizings, id: :uuid do |t|
    	t.string :aws_account_id
    	t.string :region
    	t.json :data
      t.float :cost_save_per_month
      t.float :price
      t.float :resize_price
      t.string :type
      t.timestamps
    end
    add_index :aws_right_sizings, :type
  end
end
