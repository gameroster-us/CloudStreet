# RSpec::Matchers.define :have_store_accessor do |field|
#   match do |object_instance|
#     object_instance.respond_to?(field) && object_instance.respond_to?("#{field}=")
#   end

#   failure_message do |object_instance|
#     "expected store_accessor for #{field} on #{object_instance}"
#   end

#   failure_message_when_negated do |object_instance|
#     "expected store_accessor for #{field} not to be defined on #{object_instance}"
#   end

#   description do
#     "assert there is a store_accessor of the given name on the supplied object"
#   end
# end
