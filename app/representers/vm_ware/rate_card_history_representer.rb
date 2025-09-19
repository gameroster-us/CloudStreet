# frozen_string_literal: true

module VmWare
  module RateCardHistoryRepresenter
    include Roar::JSON

    VmWareRateCard.attribute_names
                  .reject { |attr| VmWareRateCard::DISPLAY_EXCLUDE_FIELDS.include?(attr) }
                  .each do |attr|
      property attr.to_sym
    end

    property :modifier_name
  end
end
