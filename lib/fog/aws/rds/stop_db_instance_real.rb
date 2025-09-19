module Fog 
  module AWS 
    class Rds 
      class StopDBInstanceReal
      end 

      StopDBInstanceReal.class_eval do
        def stop_db_instance(instance_identifier)
          request({
                    'Action'  => 'StopDBInstance',
                    'DBInstanceIdentifier' => instance_identifier,
                    :parser   => Fog::Parsers::AWS::RDS::Base.new,
          })
        end  
      end 
    end   
  end
end 
