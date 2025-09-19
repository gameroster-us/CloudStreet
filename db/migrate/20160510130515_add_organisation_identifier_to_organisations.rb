class AddOrganisationIdentifierToOrganisations < ActiveRecord::Migration[5.1]
  def change
  	add_column :organisations, :organisation_identifier, :string,  uniqueness: true
  	Organisation.all.each do |organisation|
  		organisation.update_attribute :organisation_identifier, generate_identifier 
  	end if Organisation.count>0
  	change_column :organisations, :organisation_identifier, :string, null: false
  end

  private 

  def generate_identifier
  	last_value = Organisation.maximum(:organisation_identifier)
  	last_value.nil? ? 'K0000001' : last_value.next
  end
end
