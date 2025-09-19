class Dashboard::Statistics < CloudStreetService
  class << self
    def get(organisation, &block)
      status Status, :success, { estimated_monthly_cost: CostSummary.projected_current_months_cost(account_id: organisation.account.id) }, &block
    end
  end
end
