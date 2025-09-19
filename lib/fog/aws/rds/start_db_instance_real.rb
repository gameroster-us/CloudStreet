module Fog 
  module AWS
    class Rds
      class StartDBInstanceReal 
      end 
      StartDBInstanceReal.class_eval do
        def start_db_instance(instance_identifier)
          request({
                    'Action'  => 'StartDBInstance',
                    'DBInstanceIdentifier' => instance_identifier,
                    :parser   => Fog::Parsers::AWS::RDS::Base.new,
          })
        end
      end
    end  
  end 
end   