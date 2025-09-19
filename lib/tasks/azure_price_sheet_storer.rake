# frozen_string_literal: false

# rake azure_price_sheet_storer:store_price_sheet
namespace :azure_price_sheet_storer do
  task store_price_sheet: :environment do
    CSLogger.info '=====  azure_price_sheet_storer worker started ======'
    Azure::PriceSheetFetcherWorker.perform_async
  end
end
