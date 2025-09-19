FactoryBot.define do
  factory :tenant do
    name { "Default" }
    state { nil }
    association :organisation
    tags { {} }
    sso_keywords { [] }
    exclude_edp { nil }
    enable_currency_conversion { nil }
    default_currency { nil }
    report_profile_id { nil }
    all_selected_flags { {"AWS"=>{"is_adapter"=>true}, "GCP"=>{"is_adapter"=>true}, "Azure"=>{"is_adapter"=>true, "is_resource_groups"=>true}, "VmWare"=>{"is_adapter"=>true}} }
  end
end
