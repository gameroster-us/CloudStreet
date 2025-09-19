class OrganisationUser < ApplicationRecord
  self.table_name = "organisations_users"
  belongs_to :organisation
  belongs_to :user
  
  validates_uniqueness_of :user_id, :scope => :organisation_id, :message => "user already exist"

  scope :by_organisation, ->(organisation_id){where(organisation_id: organisation_id)}
  scope :active, ->{where(state: "active")}

  state_machine initial: :invited do

    event :active do
      transition [:invited, :disabled, :pending] => :active
    end

    event :disable do
      transition :active => :disabled
    end
    
  end


end
