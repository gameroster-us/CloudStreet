# FactoryBot.define do
#   factory :compute, class: Services::Compute do
#     architecture 'x86'
#     after(:build) { |compute|
#       Services::NetworkInterface.partial_writes = false

#       nic = Services::NetworkInterface.new
#       nic.service.name = 'NIC'
#       nic_cpu = nic.add_interface('i-compute', Protocol::Network.to_s)

#       compute.service.name = 'Compute'
#       compute.add_interface('i-nic', Protocol::Network.to_s)
#       cpu_disk = compute.add_interface('i-disk', Protocol::Disk.to_s)
#       compute.add_relationship('i-nic', nic_cpu, Protocol::Network.to_s)

#       volume = Services::Volume.new
#       volume.service.name = 'Volume'
#       volume.add_interface('i-compute', Protocol::Disk.to_s)
#       volume.add_relationship('i-compute', cpu_disk, Protocol::Disk.to_s)
#     }
#   end
# end
