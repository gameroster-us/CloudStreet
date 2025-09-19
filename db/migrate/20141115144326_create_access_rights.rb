class CreateAccessRights < ActiveRecord::Migration[5.1]
  def change
    create_table :access_rights, id: :uuid do |t|
      t.string :title
 		  t.string :code,:unique=>true
    	t.timestamps
    end
  end
end
