class AccountSoeScriptsRemoteSource < ApplicationRecord
  self.table_name = "accounts_soe_scripts_remote_sources"
  belongs_to :soe_scripts_remote_source, class_name: "SoeScripts::RemoteSource"
  belongs_to :account
end
