# frozen_string_literal: false

# Model for App Service Plan
class Azure::Resource::Web::AppServicePlan < Azure::Resource::Web
  include Synchronizers::Azure
  include Azure::Resource::RemoteAction
  include Azure::Resource::CostCalculator

  AZURE_RESOURCE_TYPE = 'Microsoft.Web/serverFarms'.freeze
  FREE_TIER = 'Free'.freeze
  SHARED_TIER = 'Shared'.freeze

  delegate :azure_app_service_plan, to: :adapter, allow_nil: true

  alias_method :client, :azure_app_service_plan

  store_accessor :data, :apps, :os, :zone_redundant, :sku, :status

  scope :unused_plans, -> { where("data->>'apps'='0'") }
  scope :exclude_free_plans, -> { where.not("data->'sku'->>'tier'=?", FREE_TIER) }
  scope :exclude_shared_plans, -> { where.not("data->'sku'->>'tier'=?", SHARED_TIER) }
  scope :in_used_plans, -> { where.not(id: unused_plans) }

  def is_linux?
    os == 'linux'
  end
end
