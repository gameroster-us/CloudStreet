module MarketplaceAdapterUpdater
  def self.included base
    base.instance_eval do
      def update_bucket_id(adapter, params, user, &block)
        adapter.bucket_id        = params[:adapter][:bucket_id]
        adapter.bucket_region_id = params[:adapter][:region_id]
        adapter.user = user      
        test_result = adapter.verify_bucket_id
        if test_result[:result] && !params[:is_bucket_for_reports]
          region = Region.find(params[:adapter][:region_id])
          MarketplaceAmiSettingsManager.update_s3_config(adapter, region, params[:adapter][:bucket_id])
          status AdapterStatus, :success, adapter, &block
        elsif test_result[:result] && params[:is_bucket_for_reports]
          adapter.save!
          status AdapterStatus, :success, adapter, &block
        else
          status AdapterStatus, :validation_error, error_type: test_result[:error], &block
        end
      end  
    end    
  end
end
