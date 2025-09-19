class ChangeAccountIdColumnConstraintOfTemplates < ActiveRecord::Migration[5.1]
  def change
    change_column :templates, :account_id, :uuid, :null => true
  end
end
