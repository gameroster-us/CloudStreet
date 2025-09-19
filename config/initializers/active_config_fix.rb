def define_methods_recursively(obj)
  case obj
  when Config::Options
    obj.each_pair do |key, value|
      obj.define_singleton_method(key) { value }
      define_methods_recursively(value) 
    end
  when Array
    obj.each { |item| define_methods_recursively(item) }
  end
end

Settings.each_pair do |key, value|
  Settings.define_singleton_method(key) { value }
  define_methods_recursively(value)
end