class TemplateSearcher < CloudStreetService

  def self.search(account, tenant, user, page_params, search_params, &block)
    account = fetch Account, account
    # templates = Template.includes(services: [interfaces: [:connections]])
    #                     .where(account: account).order(updated_at: :desc).unarchived.load
    adapter_ids = tenant.adapters.pluck(:id)
    templates = Template.includes(:adapter).where(adapter_id: adapter_ids, account_id: account.id).unarchived.order(updated_at: :desc) if search_params['template_type'] == "non_generic"
    #templates = Template.includes(:adapter).unarchived.order(updated_at: :desc)
    templates = Template.includes(:adapter).generic_type.unarchived.order(updated_at: :desc) if search_params['template_type'] == "generic"
    templates = templates.account_with_public(account.id) if search_params['template_type'].blank?
    templates = templates.search_user_accessible_templates(user, tenant)
    templates = templates.where("templates.name ILIKE ?", "%#{search_params[:name]}%") if search_params[:name].present?
    templates = templates.eager_load(:adapter).find_adapter(search_params[:adapter_id]) if search_params[:adapter_id].present?
    templates = templates.eager_load(:region).find_region(search_params[:region_id]) if search_params[:region_id].present?
    templates = templates.from_date(search_params[:from_date]) if  search_params[:from_date].present?
    templates = templates.till_date(search_params[:to_date]) if search_params[:to_date].present?
    templates = templates.by_state(search_params[:state]) if search_params[:state].present?
    templates = templates.where(adapters: {type: "Adapters::#{search_params[:provider]}"}) if search_params[:provider].present? && ["AWS","Azure"].include?(search_params[:provider])
    unless search_params[:access].blank?
      case search_params[:access]
      when "1"
        templates = templates.accessible_by_user(user.id)
      when "2"
        templates = templates.accessible_by_group(user.user_roles.pluck(:id))
      when "3"
        templates = templates.accessible_by_everyone
      end
    end

    templates, total_records = apply_pagination(templates, page_params)

    status Status, :success, [templates, total_records], &block
    templates
  end

  def self.top_templates(account, &block)
    account = fetch Account, account

    templates = Template.unarchived
                .where(account_id: account.id)
                .order(updated_at: :desc)
                .limit(4)
                .load

    status Status, :success, templates, &block
    templates
  end
  def self.find(template, &block)
    template = fetch Template, template

    status Status, :success, template, &block
  end


  def self.get_revision_data(template_id, revision_number, &block)
    revision_number = Float(revision_number) rescue 0.0
    from_event = Event.where("data->>'template_id'= ? AND data->'revision_data'->>'number'= ?", template_id.to_s, revision_number.to_s).first

    if from_event.nil?
      message = "Sorry, copy template is unavailable for older templates. "
      return status  Status, :error, { message: message }, &block
    else
      events = Event.where("data->>'template_id'= ? AND created_at <= ?", template_id.to_s, from_event.try(:created_at))
      deleted_service_ids = []
      subnet_events = events.order('created_at').inject([]) do |subnet_events_arr, agg_events|
        agg_events.data['revision_data']['services_data'].each do |id, service_data|
          next(deleted_service_ids) unless CommonConstants::REVISION_SERVICES.include?(service_data["generic_type"])
          deleted_service_ids << id if service_data['action'] == 'deleted'
          deleted_service_ids
        end
        deleted_service_ids = deleted_service_ids.reject(&:blank?)
        agg_events.data['revision_data']['services_data'].each do |service_id, service_hash|

          next unless CommonConstants::REVISION_SERVICES.include?(service_hash["generic_type"])

          next if deleted_service_ids && deleted_service_ids.include?(service_hash['id'])
          service_hash = service_hash.except('properties') if service_hash['generic_type'].exclude?('Services::Network::Subnet')
          subnet_events_arr << {"id" => service_id}.merge!(service_hash)
        end
        subnet_events_arr
      end
      subnet_events.reject! {|ar_hash| deleted_service_ids && deleted_service_ids.include?(ar_hash['id']) }
      status Status, :success, subnet_events, &block
    end
  end
end
