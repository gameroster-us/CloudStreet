#
module HstoreAccessor
  def self.included(base)
    base.extend(ClassMethods)
  end

  #
  module ClassMethods
    def uses_hstore?
      false
    end

    def valid_for_hstore?(hstore_attribute, key)
      self.hstore_attributes[hstore_attribute].include? key if self.hstore_attributes[hstore_attribute]
    end

    def hstore_accessor(hstore_attribute, *keys)
      if !uses_hstore?
        class_attribute :hstore_attributes, :belongs_to_hstore_attributes
        self.hstore_attributes = {}
        self.belongs_to_hstore_attributes = []

        class_eval do
          def []=(attr_name, value)
            #CSLogger.info "[]=(#{attr_name}, #{value})"
            if self.belongs_to_hstore_attributes.include? attr_name.to_sym
              send("#{attr_name}=", value)
            else
              super(attr_name, value)
            end
          end

          def [](attr_name)
            #CSLogger.info "[](#{attr_name})"
            if self.belongs_to_hstore_attributes.include? attr_name.to_sym
              send("#{attr_name}")
            else
              super(attr_name)
            end
          end

          def self.uses_hstore?
            true
          end
        end
      end

      if !self.hstore_attributes.has_key? hstore_attribute.to_sym
        self.hstore_attributes[hstore_attribute.to_sym] = []
      end

      Array(keys).flatten.each do |key|
        self.hstore_attributes[hstore_attribute.to_sym] |= [key]

        attr_writer key.to_sym
        define_method("#{key}=") do |value|
          send("#{hstore_attribute}=", (send(hstore_attribute) || {}).merge(key.to_s => value))
          send("#{hstore_attribute}_will_change!")
        end
        define_method(key) do
          send(hstore_attribute) && send(hstore_attribute)[key.to_s]
        end
      end
    end

    def belongs_to(name, options = {})
      # CSLogger.info "belongs_to(#{name}, #{options})"
      hstore = options.delete :hstore
      f_key = options[:foreign_key] || "#{name.to_s}_id"

      belongs_to_hstore hstore.to_s, f_key.to_sym if hstore
      # relation = super(name, options)
      super(name, **options)
    end

    def belongs_to_hstore(hstore_attribute, *keys)
      #CSLogger.info "belongs_to_hstore(#{hstore_attributes}, #{keys})"
      hstore_accessor(hstore_attribute, *keys)

      self.belongs_to_hstore_attributes |= Array(keys)
    end
  end
end

ActiveRecord::Base.send(:include, HstoreAccessor)
