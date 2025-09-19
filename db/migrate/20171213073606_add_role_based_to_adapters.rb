class AddRoleBasedToAdapters < ActiveRecord::Migration[5.1]
  def self.up
    return if (ENV['SAAS_ENV'] == true || ENV['SAAS_ENV'] == 'true')
    begin
     IamAdapterRectifier.rectify
     Adapters::AWS.where.not(state: :directory).where("data ? 'role_arn'").each{|adapter|
       adapter.data = adapter.data.merge({role_based: true})
       adapter.data_will_change!
       adapter.save!
     }
    rescue Exception => e
      puts e.class
      puts e.message
      puts e.backtrace
    end
  end
end
