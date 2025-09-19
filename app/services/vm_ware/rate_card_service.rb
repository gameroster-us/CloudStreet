# frozen_string_literal: true

module VmWare
  class RateCardService < CloudStreetService
    class << self
      def get_rate_card(account, req_params, &block)
        with_rescue(proc { status(Status, :success, fetch_rate_card(account, req_params), &block) })
      end

      def update_rate_card(account, vmware_rate_card_params, &block)
        executables = proc do
          load_mongo_db(account)
          vmware_rate_card = VmWareRateCard.find(vmware_rate_card_params[:id])
          adapter_id = vmware_rate_card_params[:adapter_id]
          vmware_rate_card.assign_attributes(vmware_rate_card_params)
          if vmware_rate_card.changed?
            if vmware_rate_card.save
              update_adapters_sync_data(account, vmware_rate_card, adapter_id) unless vmware_rate_card.versions.count.positive?
              store_version(vmware_rate_card)
              status(Status, :success, response_format(vmware_rate_card), &block)
            else
              status(Status, :validation_error, vmware_rate_card.errors.messages, &block)
            end
          else
            status(Status, :success, response_format(vmware_rate_card).merge!(changed: false), &block)
          end
        end

        with_rescue(executables, account_id: account.id, params: vmware_rate_card_params, &block)
      end

      def create_rate_card(account, vmware_rate_card_params, &block)
        load_mongo_db(account)

        executables = proc do
          vmware_rate_card = VmWareRateCard.new(vmware_rate_card_params)
          adapter_id = vmware_rate_card_params[:adapter_id]
          if vmware_rate_card.save
            update_adapters_sync_data(account, vmware_rate_card, adapter_id)
            store_version(vmware_rate_card)
            status(Status, :success, response_format(vmware_rate_card), &block)
          else
            status(Status, :validation_error, vmware_rate_card.errors.messages, &block)
          end
        end
        with_rescue(executables, account_id: account.id, params: vmware_rate_card_params, &block)
      end

      def delete_rate_card(account, rate_card_id, &block)
        load_mongo_db(account)
        rate_card = VmWareRateCard.find(rate_card_id)
        adapter_id = rate_card.adapter_id if rate_card
        if rate_card.present?
          if rate_card.delete
            update_adapters_unsync_data(account, adapter_id)
            status(Status, :success, nil, &block)
          else
            status(Status, :validation_error, rate_card.errors.messages, &block)
          end
        else
          status(Status, :validation_error, "Rate card not present with this id: #{rate_card_id}", &block)
        end
      end


      def update_adapters_unsync_data(account, adapter_id)
        Adapters::VmWare
          .where(account_id: account.id, id: adapter_id)
          .update_all(data: {})
      end

      def get_history(account, params, &block)
        executables = proc do
          rc_id = params[:id]
          vmware_rate_card = fetch_rate_card(account, params, rc_id).last
          if vmware_rate_card.present?
            paginated_result = vmware_rate_card.versions
                                               .order_by(updated_at: :desc)
                                               .paginate(per_page: params[:page_size], page: params[:page_number])
            status(Status, :success, { result: paginated_result, total_count: vmware_rate_card.versions.count }, &block)
          else
            status(Status, :validation_error, { rate_card: 'Not found' }, &block)
          end
        end

        with_rescue(executables, account_id: account.id, &block)
      end

      private

      def fetch_rate_card(account, req_params = {}, rate_card_id = nil)
        load_mongo_db(account)
        rate_card_id = rate_card_id || req_params[:rate_card_id]
        return VmWareRateCard.where(id: rate_card_id, account_id: account.id) if rate_card_id 

        if req_params[:name].present?
          adapter_ids = Adapters::VmWare.where(account_id: account.id).where('lower(name) like ?', "%#{req_params[:name].downcase}%").pluck(:id)
          return [] if adapter_ids.blank?

          rate_cards = VmWareRateCard.where(:account_id => account.id, :adapter_id.in => adapter_ids).order(%i[created_at desc])
        else
          adapter_ids = Adapters::VmWare.where(account_id: account.id).pluck(:id)
          rate_cards = VmWareRateCard.where(account_id: account.id, :adapter_id.in => adapter_ids).order(%i[created_at desc])
        end
        if req_params[:page_size].present?
          rate_cards.paginate(per_page: req_params[:page_size].to_i, page: req_params[:page_number].to_i) 
        else
          rate_cards
        end
      end

      def load_mongo_db(account)
        load_mongoid_db_entry(account)
        CurrentAccount.client_db = account
      end

      def load_mongoid_db_entry(account)
        MongodbService.process_migration(account, account.organisation_identifier)
      end

      def response_format(vmware_rate_card)
        vmware_rate_card = vmware_rate_card.as_json
        vmware_rate_card['id'] = vmware_rate_card.delete '_id'
        vmware_rate_card['id'] = vmware_rate_card['id'].to_s
        vmware_rate_card.reject { |rc| VmWareRateCard::DISPLAY_EXCLUDE_FIELDS.include?(rc) }
      end

      def store_version(vmware_rate_card)
        version_attrs = vmware_rate_card.attributes.except('_id').tap do |version|
          version[:modifier_name] = vmware_rate_card.modifier_name
        end
        vmware_rate_card.versions.create!(version_attrs)
      end

      def update_adapters_sync_data(account_id, vmware_rate_card, adapter_id)
        Adapters::VmWare
          .where(account_id: account_id, id: adapter_id)
          .where("data->'rate_card_created_at' is null")
          .update_all([%(data = data || hstore(?,?)), 'rate_card_created_at', vmware_rate_card.created_at])
      end

      def with_rescue(executables, **params, &block)
        executables.call
      rescue StandardError => e
        CSLogger.error "\nVmWare::RateCardService::Error: #{e.message}\n Backtrace: #{e.backtrace}"
        if ENV['HONEYBADGER_API_KEY']
          Honeybadger.notify(e,
                             error_class: 'VmWare::RateCardService',
                             error_message: e.message,
                             parameters: params)
        end
        status(Status, :error, 'Oops... Something went wrong!', &block)
      end
    end
  end
end
