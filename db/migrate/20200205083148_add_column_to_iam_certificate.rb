class AddColumnToIamCertificate < ActiveRecord::Migration[5.1]
  def change
    add_column :iam_certificates, :account_id, :uuid
  end
end
