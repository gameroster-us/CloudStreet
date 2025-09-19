class ConverJsonToJsonbInRateCard < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  def change
    reversible do |dir|
      dir.up do
        migrate_json_to_jsonb :azure_rate_cards, :rates
      end
      dir.down do
        migrate_jsonb_to_json :azure_rate_cards, :rates
      end
    end
  end

  def migrate_json_to_jsonb(table, attribute)
    change_column table, attribute, "jsonb USING #{attribute}::JSONB", default: {}, null: false
    
    enable_extension "btree_gin"
    add_index table, attribute, using: :gin, algorithm: :concurrently
  end

  def migrate_jsonb_to_json(table, attribute)
    remove_index table, attribute
    change_column table, attribute, "json USING #{attribute}::JSON", default: {}, null: false
  end
end
