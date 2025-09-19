class CreateCSServiceTagsView < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE VIEW service_tags AS
        SELECT st.CS_service_id, v.tag_value, t.key, t.adapter_id, t.subscription_id, t.region_id, ks.service_type, ks.name, ks.provider_id    
        FROM CS_services_tag_key_values as st 
        LEFT JOIN CS_services as ks ON st.CS_service_id = ks.id 
        LEFT JOIN tag_key_values as v ON st.tag_key_value_id = v.id    
        LEFT JOIN tag_keys as t ON v.tag_key_id = t.id;
    SQL
  end

  def down
    execute "DROP VIEW service_tags"
  end
end
