require 'deep_cloneable'

class TemplateCloneable

  def self.clone_from_template(template, user, name)
    puts "CLONING TEMPLATE FROM TEMPLATE YO"
    namez = name ? name : template.name

    puts "Current Template:"
    template.services.each do |s|
      puts "  service: #{s.type} / #{s.id}"
      puts "  interfaces:"
      s.interfaces.each do |i|
        puts "    #{i.name} / #{i.id}"
        puts "    connections:"
        i.connections.each do |c|
          puts "      #{c.id}"
        end
      end
    end

    e = Template.new(name: namez, account: template.account)
    #e.id = SecureRandom.uuid

    template.services.each do |s|
      puts s.inspect
      new_service = s.dup #(include: [:interfaces]) #: [:remote_interfaces]]) #: [:connections]])
      #new_service.id = SecureRandom.uuid
      new_service.state = :pending

      e.services << new_service
    end

#     template.services.each do |s|
#       s.interfaces.each do |i|
#         new_interface = i #.clone
# #        new_interface.id = SecureRandom.uuid
#         s.interfaces << new_interface
#       end
#     end
    # now we need to update ids....
    # e.id = SecureRandom.uuid
    # e.services.each do |s|
    #   s.id = SecureRandom.uuid
    #   s.interfaces.each do |i|
    #     i.id = SecureRandom.uuid
    #     i.connections.each do |c|
    #       c.id = SecureRandom.uuid
    #     end
    #   end
    # end

    puts "New Template:"
    e.services.each do |s|
      puts "  service: #{s.type} / #{s.id}"
      puts "  interfaces:"
      s.interfaces.each do |i|
        puts "    #{i.name} / #{i.id}"
        puts "    connections:"
        i.connections.each do |c|
          puts "      #{c.id}"
        end
      end
    end

#     template.services.each do |s|
#       s.interfaces.each do |i|
#         i.connections.each do |c|
#           new_connection = c.clone

#           puts "NEW CONNECTION:"
#           puts new_connection.inspect

#           puts "local interface"
#           puts new_connection.interface.inspect

#           puts "remote interface"
#           puts new_connection.remote_interface.inspect


# #          new_connection.id = SecureRandom.uuid
#           #i.connections << new_connection
#         end
#       end
#     end

    puts e.inspect

    e.save!
    e
  end
end
