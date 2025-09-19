# frozen_string_literal: true

namespace :organisation_adapters do
  desc 'Create Organisation adapters'
  task bulk_create: :environment do
    Organisation.find_each(batch_size: 1000) do |organisation|
      adapters = organisation.try(:account).try(:adapters)
      next if adapters.blank?

      adapters.each do |adapter|
        OrganisationAdapter.find_or_create_by(organisation_id: organisation.id, adapter_id: adapter.id)
      end
    end
  end
end
