# frozen_string_literal: true

module Azure
  # Store Retail price information
  class RetailPriceList
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    index({ prices: 1 })
    index({ region_code: 1 })
    index({ resource_type: 1 })

    field :prices
    field :resource_type
    field :region_code

    scope :virtual_machine_prices, -> { where(resource_type: 'Virtual Machines') }
    scope :sql_database_prices, -> { where(resource_type: 'SQL Database') }
    scope :storage_prices, -> { where(resource_type: 'Storage') }
    scope :maria_database_prices, -> { where(resource_type: 'Azure Database for MariaDB') }
    scope :postgres_database_prices, -> { where(resource_type: 'Azure Database for PostgreSQL') }
    scope :mysql_database_prices, -> { where(resource_type: 'Azure Database for MySQL') }
    scope :azure_kubernetes_service, -> { where(resource_type: 'Azure Kubernetes Service') }
    scope :app_service, -> {where(resource_type: 'Azure App Service')}
    scope :app_service_plan, -> {where(resource_type: 'Azure App Service')}

    def self.sqldb
      where(resource_type: 'sqldb')
    end

    def reserved_vm_prices
      prices.select { |retail_price| retail_price['type'].try(:downcase).eql?('reservation') }
    end

    def select_by_vm_sku(vm_sku)
      return [] unless resource_type.eql?('Virtual Machines')

      prices.select {|retail_price| (retail_price['armSkuName'].try(:downcase)).eql?(vm_sku.try(:downcase))}
    end

    def select_by_meter_name()
      prices.find { |retail_price| retail_price['meterName'].try(:downcase).eql?('uptime sla') }
    end

    def select_by_app_service_plan_meter_name(sku)
      return [] unless resource_type.eql?('Azure App Service')

      prices.select {|retail_price| (retail_price['meterName'].delete(' ').try(:downcase)).eql?(sku['name'].delete(' ').try(:downcase))}
    end

    def select_by_app_service_meter_name(meter_name)
      return [] unless resource_type.eql?('Azure App Service')

      prices.select {|retail_price| (retail_price['meterName'].delete(' ').try(:downcase)).eql?(meter_name.try(:downcase))}
    end
  end
end
