class MatricMaxUsageStorage

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  STORAGE_TYPE = {
            'io1' => 'Provisioned IOPS SSD(io1)',
            'gp2' => 'General Purpose SSD (gp2)'
          }.freeze

  field :aws_account_id
  field :adapter_id
  field :region_id
  field :provider_id
  field :provider_type
  field :provider_name
  field :current_storage_type
  field :recommanded_storage_type
  field :tag
  field :case_insensitive_tag
  field :current_iops_usage
  field :recommanded_iops_usage
  field :state
  field :actual_estimation_cost
  field :recommanded_estimation_cost
  field :created_at, type: DateTime, default: -> { Time.now }
  field :updated_at, type: DateTime, default: -> { Time.now }
  field :ignored_from, default: -> { ['un-ignored'] }
  attr_accessor :comment_count

  index({ adapter_id: 1 })

  class << self

    #initize params for storage
    def init_storage(object, matric_params)
      if object
        params = {
        aws_account_id: matric_params[:adapter].aws_account_id,
        adapter_id: matric_params[:adapter].id,
        region_id: matric_params[:region].id,
        provider_id: object.id,
        provider_type: matric_params[:provider_type],
        provider_name: (object.tags.present? && object.tags["Name"].present?) ? object.tags["Name"] : object.id,
        current_storage_type: matric_params[:provider_type] == "Services::Database::Rds::AWS" ? object.storage_type : object.type,
        recommanded_storage_type: matric_params[:recommanded_storage_type],
        tag: object.tags,
        case_insensitive_tag: object.tags.transform_keys(&:downcase).transform_values(&:downcase),
        recommanded_iops_usage: matric_params[:recommanded_iops_usage],
        current_iops_usage: matric_params[:current_iops_usage],
        recommanded_estimation_cost: matric_params[:recommanded_estimation_cost].nil? ? 0 : matric_params[:recommanded_estimation_cost],
        actual_estimation_cost: matric_params[:actual_estimation_cost].nil? ? 0 : matric_params[:actual_estimation_cost],
        state: object.state
        }
        create_storage(params)
      end
    end

    #storage data in table
    def create_storage(params)
      MatricMaxUsageStorage.create(params)
    end

  end

end
