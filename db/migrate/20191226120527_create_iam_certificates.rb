class CreateIamCertificates < ActiveRecord::Migration[5.1]
  def change
    create_table :iam_certificates, id: :uuid do |t|
      t.string :path
      t.string :server_certificate_name
      t.string :server_certificate_id
      t.string :arn
      t.datetime :upload_date
      t.datetime :expiration
      t.string :aws_account_id

      t.timestamps
    end
  end
end
