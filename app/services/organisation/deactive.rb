class Organisation::Deactive < CloudStreetService

  def self.deactive_organisation(organisation, user, &block)
    if organisation.owner.try(:id).eql?(user.id)
      organisation.mark_as_deactive
      status Status, :success, nil, &block
    else
      status Status, :error, "Unable to deactive organisation.", &block
    end
  end

end