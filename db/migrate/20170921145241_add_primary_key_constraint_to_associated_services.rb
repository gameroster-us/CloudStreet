class AddPrimaryKeyConstraintToAssociatedServices < ActiveRecord::Migration[5.1]
  def up
    execute "ALTER TABLE associated_services DROP CONSTRAINT IF EXISTS associated_services_pkey;"
    execute "ALTER TABLE associated_services ADD PRIMARY KEY (id);"
  end

  def down
    execute "ALTER TABLE associated_services DROP CONSTRAINT associated_services_pkey;"
  end
end
