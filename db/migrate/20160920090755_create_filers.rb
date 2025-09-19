class CreateFilers < ActiveRecord::Migration[5.1]   
 def change    
   create_table :filers, id: :uuid do |t|    
     t.string :name    
     t.uuid :adapter_id    
     t.uuid :region_id   
     t.uuid :vpc_id    
     t.uuid :security_group_id   
     t.uuid :account_id    
     t.json :data    
     
     t.timestamps    
   end   
 end   
end