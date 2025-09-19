module SecurityScanners::ScannerObjects::ObjectParser

  	def parse(object, &block)
  		if object.is_a?Array
	  		object.each { |ob| yield(create_new(ob)) }
  		else
  			yield(create_new(object))
  		end
  	end

end
