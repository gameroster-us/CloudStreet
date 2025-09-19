module SubnetsRepresenter
include Roar::JSON
include Roar::Hypermedia

  	collection(
      	:subnets,
      	extend: SubnetRepresenter,
      	embedded: false
    )

 	def subnets
 		collect
 	end
end