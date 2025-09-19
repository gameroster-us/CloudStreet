module Sync
  module BaseSyncWorker
    attr_accessor :failed
    def wrapper(account_id, resource_id, &block)
      @synchronizer = ServiceSynchronizer.new(account_id)
      begin
        block.call(@synchronizer)
      ensure
        if @failed
            @synchronizer.failed(resource_id)
            ::NodeManager.send_sync_progress(
              @synchronizer.account_id, [{
              id: resource_id,
              sync_state: Synchronization::FAILED,
              error_message: "failed"
              }]
            )
          raise "failed"
        end
      end
    end
  end
end