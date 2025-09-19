# Currently this module is only used by environment.rb and account.rb, both of which have a variable services. But this is not a gurantee
# and when using this module with other classes we will need another way of defining how to get the objects. To do this we would define a method
# that would need to be implemented by the implementing class.
# Refer to: http://stackoverflow.com/questions/2490699/pass-arguments-to-included-module-in-ruby
# Any one of the 3 gems mentioned in that stackoverflow page will work: Paramix, Modularity or ActionModel
module Behaviors::RestrictedObjects
  def active_accountable_objects
    self.services.select{ |service| service.object_restricted? && accountable_service?(service) }
  end

  def accountable_service?(service)
    service.starting? || service.running?
  end
end