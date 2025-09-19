require "uber/delegates"
require "uber/callable"
require "declarative/option"
require "declarative/schema"

require "representable/config"
require "representable/definition"
require "representable/declarative"
require "representable/deserializer"
require "representable/serializer"
require "representable/binding"
require "representable/pipeline"
require "representable/insert" # Pipeline::Insert
require "representable/cached"
require "representable/for_collection"
require "representable/represent"

module Representable
  attr_writer :representable_attrs

  def self.included(base)
    base.class_eval do
      extend Declarative
      # make Representable horizontally and vertically inheritable.
      extend ModuleExtensions, ::Declarative::Heritage::Inherited, ::Declarative::Heritage::Included
      extend ClassMethods
      extend ForCollection
      extend Represent
    end
  end

  private

  OptionsForNested = ->(options, binding) do
    child_options = {user_options: options[:user_options], }

    # wrap:
    child_options[:wrap] = binding[:wrap] unless binding[:wrap].nil?
    # TODO: Can we make it better by using Meta-programming so
    # all future keys will be work, no need to specify here?
    [:with_group_images, :with_configs, :with_buckets, :current_user, :current_account, :start_datetime, :end_datetime, :total_records, :cleared_task_ids, :template_errors, :cost_options, :object].each do |key|
      child_options.merge!(key => options[key]) if options[key].present?
    end
    merge_children = {}    
    merge_children = options[binding.name.to_sym] if options[binding.name.to_sym].is_a?(Hash)    
    child_options.merge!(merge_children) if merge_children.present?    
    child_options
  end

  module ModuleExtensions
    # Copies the representable_attrs reference to the extended object.
    # Note that changing attrs in the instance will affect the class configuration.
    def extended(object)
      super
      object.representable_attrs=(representable_attrs) # yes, we want a hard overwrite here and no inheritance.
    end
  end

  module ClassMethods
    def prepare(represented)
      # TODO: Need to `dup` the object, in `tags` API, `represented` is freeze
      # So dup the object to make it work
      begin
        represented_dup = represented.frozen? ? represented.dup : represented
        represented_dup.extend(self)
      rescue Exception => e
        represented.extend(self)
      end
    end
  end
end
