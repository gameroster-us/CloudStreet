class UpdateTasksForAllAccounts < ActiveRecord::Migration[5.1]
  def change
    accounts = Account.all
    accounts.each do |account|
      account.tasks.each do |task|
        next unless task.schedule.is_a?(Hash)
        begin
          task.schedule = IceCube::Schedule.from_hash(task.schedule)
          task.save(validate: false)
        rescue Exception => e
          CSLogger.error("#{e.backtrace}")
        end
      end
    end
  end
end
