class TemplateCosts::Parsers::ElasticIP < TemplateCost

  class << self

    def parse(parsed_file, product_keys)
      product_keys.each_with_object({}) do |(product_group, product_sku), memo|
        price_dimentions = parsed_file["terms"]["OnDemand"][product_sku].deep_find("priceDimensions")

        case product_group
        when "ElasticIP:Remap"
          price_dimentions.each do |_, cost|
            key = cost["description"].include?("first 100 remaps / month") ? "perRemapFirst100" : "perRemapOver100"
            memo[key] = cost["pricePerUnit"]["USD"].to_f
          end
        when "ElasticIP:AdditionalAddress"
          price_dimentions.each do |_, cost|
            memo["perAdditionalEIPPerHour"] = cost["pricePerUnit"]["USD"].to_f
          end
        when "ElasticIP:Address"
          price_dimentions.each do |_, cost|
            memo["perNonAttachedPerHour"] = cost["pricePerUnit"]["USD"].to_f if cost["description"].include?("not attached to a running instance per hour")
          end
        end
      end
    end

  end

end
