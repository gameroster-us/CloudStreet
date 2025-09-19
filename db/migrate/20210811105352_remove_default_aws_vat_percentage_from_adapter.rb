class RemoveDefaultAWSVatPercentageFromAdapter < ActiveRecord::Migration[5.1]
  def change
    change_column_default(:adapters, :aws_vat_percentage, from: 18.0, to: nil)
  end
end
