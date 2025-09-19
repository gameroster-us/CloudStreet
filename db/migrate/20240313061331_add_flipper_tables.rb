class AddFlipperTables < ActiveRecord::Migration[5.2]
  def self.up
    unless ActiveRecord::Base.connection.table_exists?(:flipper_features)
      ActiveRecord::Base.connection.execute <<-SQL
        CREATE TABLE flipper_features (
          id SERIAL PRIMARY KEY,
          key text NOT NULL UNIQUE,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL
        )
      SQL
    end
    unless ActiveRecord::Base.connection.table_exists?(:flipper_gates)
      ActiveRecord::Base.connection.execute <<-SQL
        CREATE TABLE flipper_gates (
          id SERIAL PRIMARY KEY,
          feature_key text NOT NULL,
          key text NOT NULL,
          value text DEFAULT NULL,
          created_at timestamp NOT NULL,
          updated_at timestamp NOT NULL
        )
      SQL
    end
    unless ActiveRecord::Base.connection.index_exists?(:flipper_gates, [:feature_key, :key, :value])
      ActiveRecord::Base.connection.execute <<-SQL
        CREATE UNIQUE INDEX index_gates_on_keys_and_value on flipper_gates (feature_key, key, value)
      SQL
    end
  end

  def self.down
    ActiveRecord::Migration.drop_table(:flipper_features) if ActiveRecord::Base.connection.table_exists?(:flipper_features)
    ActiveRecord::Migration.drop_table(:flipper_gates) if ActiveRecord::Base.connection.table_exists?(:flipper_gates)
    ActiveRecord::Migration.remove_index "flipper_gates", name: "index_gates_on_keys_and_value" if ActiveRecord::Base.connection.index_exists?(:flipper_gates, [:feature_key, :key, :value])
  end
end
