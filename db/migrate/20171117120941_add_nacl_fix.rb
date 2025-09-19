class AddNaclFix < ActiveRecord::Migration[5.1]
  def change
  	Nacl.where(type: nil).update_all(type: "Nacls::AWS")
  end
end
