require 'csv'
class RightSizingCloudwatchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :rightsizing, retry: true, backtrace: true

  def perform(account_id, adapter_id)
    fetch_cloudwatch_metrics(account_id, adapter_id)
  end

  def fetch_cloudwatch_metrics(account_id, adapter_id)
    begin
      adapter = Adapter.find_by(id: adapter_id)
      system(`mkdir "Rightsizing/#{account_id}"`) unless File.exist?("Rightsizing/#{account_id}")
      ls_combined_csv = "Rightsizing/#{account_id}/#{account_id}.csv"
      CSV.open(ls_combined_csv,'w') { |csv| csv << CommonConstants::METRIC_COLUMN_NAMES }
      CommonConstants::AZ_CODES.keys.map{|a| a.to_s}.each do |region|
        next if region.blank? || region.eql?('global')
        ls_outputfile_name = "Rightsizing/#{account_id}/result" + "-in-" + region + ".csv"
        rc = Rightsizings::CloudwatchMetricFetcherService.new(aws_account: account_id, adapter: adapter, region: region, file_name: ls_outputfile_name)
        rc.fetch_cloudwatch_metrics
        if (File.exist?(ls_outputfile_name))
          system(`cat #{ls_outputfile_name} >> #{ls_combined_csv}`)
          system(`rm -rf #{ls_outputfile_name}`)
        end
      end
    system(`gzip -f #{ls_combined_csv}`)
    CSLogger.info "********Completed cloudwatch for account--->#{account_id}*******"
    rescue Exception => e
      CSLogger.error "Exception #{e.message}"
    end
  end
end
