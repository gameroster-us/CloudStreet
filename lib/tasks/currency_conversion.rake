namespace :currency_conversion do
  desc "Store currency conversion rate list"
  task store: :environment do
    CSLogger.info '========= started storing currency list =================='
    CurrencyFetcherWorker.perform_async
  end
end