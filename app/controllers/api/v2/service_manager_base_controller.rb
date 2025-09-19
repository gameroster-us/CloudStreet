class Api::V2::ServiceManagerBaseController < Api::V2::SwaggerBaseController
  include Api::V2::Concerns::Validator::ServiceManager
  include Api::V2::Concerns::ParamsUpdater
end