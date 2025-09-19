module UpdateServiceValidatableFinder
  class << self
    def find_and_extend!(service)
      validatable_module = find_validatable_module(service)
      service.extend(validatable_module.constantize)
    end

    def find_validatable_module(service)
      "Validatables::#{service.type}"
    end
  end
end
