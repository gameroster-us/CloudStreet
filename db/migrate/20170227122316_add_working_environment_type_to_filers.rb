class AddWorkingEnvironmentTypeToFilers < ActiveRecord::Migration[5.1]
  def change
    add_column :filers, :working_environment_type, :string
  end
end