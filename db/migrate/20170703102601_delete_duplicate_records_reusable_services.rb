class DeleteDuplicateRecordsReusableServices < ActiveRecord::Migration[5.1]
  def up
    CSLogger.info("Performing seeds in background.")
    ["SecurityGroup", "SubnetGroup"].each do |klass|
      CSLogger.info "Cleaning up duplicate records for #{klass}"
      klass.constantize.unscoped.where.not("name like '%##%'").group([:account_id,:adapter_id, :region_id,:vpc_id,:name]).having("count(name)> 1").count.each do|attrs|
        attributes = attrs.first
        services = klass.constantize.unscoped.where.not("name like '%##%'").where("account_id = ? and adapter_id = ? and region_id = ? and vpc_id = ? and name = ?",attributes[0],attributes[1],attributes[2],attributes[3],attributes[4]).all
        keep_this = nil
        keep_this = services.find{|sg| ["Complete", "available","running"].include?(sg.state) }
        services.each{|sg|
          if (keep_this && keep_this.id.eql?(sg.id))||keep_this.blank?
            keep_this ||= sg
            CSLogger.info "keeping #{klass} #{keep_this.id}"
          else
            begin
              CSLogger.info "deleting duplicate #{sg.id} #{sg.name} #{sg.state} of adapter #{sg.adapter.name} of vpc #{sg.vpc.vpc_id}"
            rescue Exception => e
              CSLogger.info "deleting duplicate #{sg.id} #{sg.name} #{sg.state} of adapter_id #{sg.adapter_id} of vpc_id #{sg.vpc_id}"
            end
            sg.delete
          end
        }
      end
    end

    CSLogger.info "finished cleaning up duplicate records"
  end
end
