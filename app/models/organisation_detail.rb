class OrganisationDetail < ApplicationRecord
  prepend MarketplaceUser if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
end