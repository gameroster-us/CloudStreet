# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :rds_configuration do
    data {
      {"mysql"=>{"-1" => []},
       "postgres"=>{"-1"=>[]},
       "sqlserver_ee"=>{"-1"=>[]},
       "sqlserver_ex"=>{"-1"=>[]},
       "sqlserver_se"=>{"-1"=>[]},
       "sqlserver_web"=>{"-1"=>[]},
       "oracle_se1"=>{"-1"=>[]},
       "oracle_se"=>{"-1"=>[]},
       "oracle_ee"=>{"-1"=>[]},
       "aurora_db"=>{"-1"=>[]}}
     }
  end
end
