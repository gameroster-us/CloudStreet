# Model for Task Details
class TaskDetails < ApplicationRecord
  include Authority::Abilities

  ## TASK DETAILS SUPPORT BELOW TYPES ONLY
  ## ["TaskDetails::AWS::Services::Server", "TaskDetails::AWS::Services::Volume","TaskDetails::AWS::Services::Rds","TaskDetails::AWS::Services::LoadBalancer","TaskDetails::AWS::Services::AutoScaling","TaskDetails::AWS::Snapshots::VolumeSnapshots","TaskDetails::AWS::Snapshots::RdsSnapshots"]
  belongs_to :task
  belongs_to :adapter

  scope :servers, -> { where(type: 'TaskDetails::AWS::Services::Server') }
  scope :volumes, -> { where(type: 'TaskDetails::AWS::Services::Volume') }
  scope :rds, -> { where(type: 'TaskDetails::AWS::Services::Rds') }
  scope :load_balancer, -> { where(type: 'TaskDetails::AWS::Services::LoadBalancer') }
  scope :auto_scaling, -> { where(type: 'TaskDetails::AWS::Services::AutoScaling') }
  scope :volumes_snapshots, -> { where(type: 'TaskDetails::AWS::Snapshots::VolumeSnapshots') }
  scope :rds_snapshots, -> { where(type: 'TaskDetails::AWS::Snapshots::RdsSnapshots') }
  scope :services, -> { where('type like ?', 'TaskDetails::AWS::Services%') }
  scope :snapshots, -> { where('type like ?', 'TaskDetails::AWS::Snapshots%') }
  scope :resources, -> { where('type like ?', 'TaskDetails::Azure::Resources%') }
  scope :virtual_machines, -> { where(type: 'TaskDetails::Azure::Resources::VirtualMachine') }
  scope :filter_by_opt_out, ->(value) { where('is_opt_out = ?', value) }
  scope :inventory, -> { where('type like ?', 'TaskDetails::VmWare%') }
  scope :machine_images, -> { where(type: 'TaskDetails::AWS::MachineImages') }
  scope :filter_by_opt_out, ->(value) { where('is_opt_out = ?', value) }
end
