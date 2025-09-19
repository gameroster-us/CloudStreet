class AddTriggerToOrganisations < ActiveRecord::Migration[5.2]
  def up
    # Create or replace the trigger function
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_organisations_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP; -- Update the updated_at column
          RETURN NEW; -- Apply changes to the row
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the BEFORE UPDATE trigger
    execute <<-SQL
      CREATE TRIGGER before_organisations_update
      BEFORE UPDATE ON organisations
      FOR EACH ROW
      EXECUTE PROCEDURE update_organisations_updated_at_column();
    SQL
  end

  def down
    # Drop the trigger and function
    execute <<-SQL
      DROP TRIGGER IF EXISTS before_organisations_update ON organisations;
    SQL

    execute <<-SQL
      DROP FUNCTION IF EXISTS update_organisations_updated_at_column();
    SQL
  end
end
