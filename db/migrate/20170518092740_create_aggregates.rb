class CreateAggregates < ActiveRecord::Migration[5.1]
  def self.up
    create_table :aggregates, id: :uuid  do |t|
      t.string :name
      t.json :available_capacity
      t.json :total_capacity
      t.string :state
      t.string :encryption_type
      t.uuid :filer_id, index: true
      t.timestamps
    end

    add_column :filer_volumes, :aggregate_id, :uuid, index: true
    execute "ALTER TABLE filer_volumes DROP CONSTRAINT IF EXISTS delete_volume_with_aggregates, ADD CONSTRAINT delete_volume_with_aggregates FOREIGN KEY (aggregate_id) REFERENCES aggregates (id) ON DELETE CASCADE;"\
    "ALTER TABLE aggregates DROP CONSTRAINT IF EXISTS delete_aggregates_with_filers, ADD CONSTRAINT delete_aggregates_with_filers FOREIGN KEY (filer_id) REFERENCES filers (id) ON DELETE CASCADE;"
  end

  def self.down
    execute "ALTER TABLE filer_volumes DROP CONSTRAINT IF EXISTS delete_volume_with_aggregates;"\
    "ALTER TABLE aggregates DROP CONSTRAINT IF EXISTS delete_aggregates_with_filers;"
    remove_column :filer_volumes, :aggregate_id
    drop_table :aggregates
  end
end
