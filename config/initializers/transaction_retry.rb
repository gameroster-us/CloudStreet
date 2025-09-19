module ActiveRecord
  class Base
    class << self
      alias_method :original_transaction, :transaction

      def transaction(*args, max_retries: 5, wait_times: [0, 1, 2, 4, 8, 16, 32, 64, 108], **kwargs)
        retries = 0

        begin
          original_transaction(*args, **kwargs) do
            yield
          end
        rescue ActiveRecord::Deadlocked => e
          if retries < max_retries

            Rails.logger.warn("Deadlock detected. Retrying transaction #{retries + 1}/#{max_retries}...")
            sleep(wait_times[retries] || wait_times.last) # Backoff before retry
            retries += 1
            retry
          else
            Rails.logger.error("Transaction failed after #{max_retries} retries due to deadlock.")
            raise e
          end
        rescue ActiveRecord::StatementInvalid => e
          if e.message.include?("PG::InFailedSqlTransaction")
            Rails.logger.error("Cannot continue with the current transaction. Ensure rollback is complete.")
            raise e
          end
        end
      end
    end
  end
end
