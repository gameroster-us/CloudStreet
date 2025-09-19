class ExportReportActivityLog < ApplicationRecord
  belongs_to :organisation
  belongs_to :tenant
end
