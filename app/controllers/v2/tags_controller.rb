module V2
  class TagsController < ApplicationController

    def index
      V2::Tags::TagsSearcher.list_all_tags(tag_params) do |result|
        result.on_success { |tags_map| render json: tags_map}
        result.on_error   { render body: nil, status: 500 }
      end
    end

    private

    def tag_params
      params.permit(:adapter_id, :subscription_id, :region_id)
    end
  end
end