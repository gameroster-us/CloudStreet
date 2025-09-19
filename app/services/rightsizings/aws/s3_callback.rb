# Callback for S3
module Rightsizings
  module AWS
    module S3Callback
      class FetchS3AccountWise
        def on_success(status, options = {})
          CSLogger.info "!!! Fetch S3 AccountWise success | options : #{options} !!!"
          S3RequestData.where(aws_account_id: options['aws_account_id'], organisation_id: options['organisation_id']).destroy_all if options.has_key?('aws_account_id') && options.has_key?('organisation_id')
          # Calling it for dashboard to update potential benefit and service count
          ServiceAdviserSummaryDataSaverWorker.perform_async(options['account_id'])
        end

        def on_complete(status, options = {})
        CSLogger.info "!!! Fetch S3 Account Wise complete | options : #{options} !!!"
        end
      end

      class FetchS3OrganisationWise
        def on_success(status, options = {})
        CSLogger.info "!! Fetch S3 Organisation Wise Success | Options : #{options['exclude_organisation'].last} !!"
        end

        def on_complete(status, options = {})
        CSLogger.info "!! Fetch S3 Organisation Wise Complete | Options : #{options['exclude_organisation'].last} !!"
          uniq_organisation_ids = Organisation.active.where.not(id: options['exclude_organisation']).ids
          exclude_organisation_ids = []
          exclude_organisation_ids << options['exclude_organisation']
          uniq_organisation_id = uniq_organisation_ids.first
          exclude_organisation_ids << uniq_organisation_id
          if uniq_organisation_id.present?
            options['exclude_organisation'] = exclude_organisation_ids.flatten
              CSLogger.info "== From S3 Organisation Callback worker | Organsiation id : #{uniq_organisation_id} =="
              S3RightSizing::FetchS3OrganisationWorker.perform_async(uniq_organisation_id, options)
          else
            CSLogger.info '**** Fetch S3 Organisation Wise full complete for all account ids ****'
          end
        end
      end
    end
  end
end
