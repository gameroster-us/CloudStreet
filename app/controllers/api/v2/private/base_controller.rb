module Private
  class Api::V2::Private::BaseController < Api::V2::ApiBaseController
    skip_before_action :authenticate_request!
    # skip_before_filter :authenticate
  end
end
