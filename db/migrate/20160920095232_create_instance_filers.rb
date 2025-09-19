class CreateInstanceFilers < ActiveRecord::Migration[5.1]   
 def change    
   create_table :instance_filers, id: :uuid do |t|   
     t.uuid :service_id    
     t.uuid :filer_id    
     
     t.timestamps    
   end   
 end
end