class AddTriggerToApplicationPlans < ActiveRecord::Migration[5.2]
  def up
    # Create or replace the trigger function
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          RAISE NOTICE 'Trigger executed for record with id: %', NEW.id;
          NEW.updated_at = CURRENT_TIMESTAMP; -- Update the updated_at column
          RETURN NEW; -- Apply changes to the row
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the BEFORE UPDATE trigger using EXECUTE PROCEDURE
    execute <<-SQL
      CREATE TRIGGER before_application_plans_update
      BEFORE UPDATE ON application_plans
      FOR EACH ROW
      EXECUTE PROCEDURE update_updated_at_column();
    SQL
  end

  def down
    # Drop the trigger and function if the migration is rolled back
    execute <<-SQL
      DROP TRIGGER IF EXISTS before_application_plans_update ON application_plans;
    SQL

    execute <<-SQL
      DROP FUNCTION IF EXISTS update_updated_at_column();
    SQL
  end
end
