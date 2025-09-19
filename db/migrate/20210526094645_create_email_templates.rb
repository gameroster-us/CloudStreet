class CreateEmailTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :email_templates, id: :uuid do |t|
      t.string :type
      t.string :subject
      t.string :body
      t.string :link
      t.json :data
      t.uuid :account_id
      t.belongs_to :organisation, foreign_key: true, type: :uuid
      t.integer :template_type
    end
  end
end
