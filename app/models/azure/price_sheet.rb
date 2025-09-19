# frozen_string_literal: true

module Azure
  # Store Retail price information
  class PriceSheet 
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    PRICESHEET_VM_CATEGORY = 'Virtual Machines'.freeze
    LOW_PRIORITY = 'Low Priority'.freeze
    PRICESHEET_SQL_DB_CATEGORY = "SQL Database".freeze

    scope :by_subscription, -> (subscription_id){ where(subscription_id: subscription_id).first }
    scope :by_region_code, -> (region_code){ where(region_code: region_code).first }
    scope :by_meter_category, -> (meter_category){ where(meter_category: meter_category).first }
    scope :virtual_machine_prices, -> { where(meter_category: PRICESHEET_VM_CATEGORY) }
    scope :sql_db_prices, -> { where(meter_category: PRICESHEET_SQL_DB_CATEGORY) }


    index({ subscription_id: 1 })
    index({ region_code: 1 })
    index({ meter_category: 1 })
    index({subscription_id: 1, region_code: 1})
    index({subscription_id: 1, region_code: 1, meter_category: 1})

    field :subscription_id
    field :region_code
    field :meter_category
    field :prices

  end
end
