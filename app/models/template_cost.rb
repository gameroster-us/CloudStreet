class TemplateCost < ApplicationRecord
  belongs_to :region
  default_scope { order('created_at DESC') }

  scope :get_aws_cost_by_regions, -> (region_ids){ where(type: 'TemplateCosts::AWS',region_id: region_ids) }

  class << self
    def of_aws
      where(type: 'TemplateCosts::AWS').first
    end

    def multi_merge(*args)
      final_args = *args
      return {} if final_args.empty?
      final_args.inject(&:merge)
    end

    def dummy_object
      new(
        id: SecureRandom.uuid,
        data: {},
        type: 'TemplateCosts::AWS',
        created_at: Time.now
      )
    end

  end
end
