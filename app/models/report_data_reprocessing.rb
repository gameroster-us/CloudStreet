# frozen_string_literal: true

class ReportDataReprocessing < ApplicationRecord

  belongs_to :adapter
  belongs_to :user

  enum status: { initiate: 0, fetching: 1, uploading: 2, glue_job_execution: 3, dashboard_generation: 4, completed: 5, failed: 6 }

end
