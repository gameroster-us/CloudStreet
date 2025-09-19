# frozen_string_literal: true

# displays list of adapters for CS
class Api::V2::CSIntegration::AdaptersController < Api::V2::ApiBaseController
  def index
    CSIntegration::Adapter::Searcher.search(current_tenant, params) do |result|
      result.on_success { |adapters| respond_with_user_and adapters, with_buckets: true, represent_with: AdaptersRepresenter }
      result.on_error   { render body: nil, status: 500 }
    end
  end
end
