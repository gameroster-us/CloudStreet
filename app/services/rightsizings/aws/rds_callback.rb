# frozen_string_literal: true

# Rds Callback
module Rightsizings
  module AWS
    module RdsCallback
      class CloudWatchMetric
        def on_success(_status, _options = {})
          Sidekiq.logger.info 'Im a here CloudWatchMetric on_success'
        end

        def on_complete(_status, options = {})
          Sidekiq.logger.info '***** Started RDS CloudWatchMetric on_complete *****'
          if options.key?('aws_account_ids') && options['aws_account_ids'].any?
            options['aws_account_ids'].each do |aws_account_id|
              AWSRightSizing::Rds.where(aws_account_id: aws_account_id).delete_all # Delete all recommendation for this aws account id.
              service_hash = { aws_account_id: aws_account_id }
              ras = Rightsizings::AWS::RdsRightSizingAnalyzingService.new(service_hash)
              ras.analyze_services
            end
          end
          Sidekiq.logger.info '***** Completed RDS CloudWatchMetric on_complete *****'

          # Calling it for dashboard to update potential benefit and service count
          if options.key?('aws_account_ids')
            Sidekiq.logger.info '---- Calling Summary Adviser Worker for Dashborad in background ----'
            account_ids = Adapters::AWS.where("data->'aws_account_id' IN (?)", options['aws_account_ids']).pluck(:account_id).compact.uniq
            account_ids.each do |account_id|
              ServiceAdviserSummaryDataSaverWorker.set(queue: 'rightsizing').perform_async(account_id)
            end
            Sidekiq.logger.info '---- Ended Summary Adviser Worker for Dashborad in background ----'
          end
        rescue StandardError => e
          Sidekiq.logger.error '***** Excpetion in RDS CloudWatchMetric on_complete *****'
          Sidekiq.logger.error e.message
        end
      end
    end
  end 
end 