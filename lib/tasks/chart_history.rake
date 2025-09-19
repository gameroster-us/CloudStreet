namespace :chart_history do
  desc "Chart History worker started"
  task reset: :environment do
    ResetChartHistoryWorker.perform_async
  end
end
