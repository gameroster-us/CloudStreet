class AddDiscountInformationToAdapters < ActiveRecord::Migration[5.1]
  def change
  	add_column :adapters, :aws_support_discount, :float
  	add_column :adapters, :aws_vat_percentage, :float, default: 18.0
  	add_column :adapters, :service_types_discount, :json, default: {}
  end
end
