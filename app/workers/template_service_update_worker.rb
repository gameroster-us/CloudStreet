class TemplateServiceUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync, backtrace: true

  def perform(options)
    template = Template.find(options["template_id"])
    adapter = Adapter.find(options["adapter_id"])
    region = Region.find(options["region_id"])
    account = Account.find(options["account_id"])
    services = template.services.active_reusable_services.group_by(&:type)
    Sync::UpdateTemplateServices.update_services_in_template(template, services, adapter, region, account)
    Sync::UpdateTemplateServices.update_template_if_vpc_deleted(template, adapter)
  end
end
