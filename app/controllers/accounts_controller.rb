class AccountsController < ApplicationController
  before_action :restrict_saas_application, only: [:register_card, :get_cards, :get_invoice_report]
  before_action :authenticate, except: [:report_notification, :favorite_report_notification]
  authority_actions get_saas_subscriptions: 'access'

  def index
    AccountSearcher.search(user) do |result|
      result.on_success { |accounts| respond_with_user_and accounts }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def show
    @account = Account.find(params[:id])
    #authorize_action_for(@account)

    AccountSearcher.find(@account) do |result|
      result.on_success { |account| respond_with_user_and account }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def update
    @account = Account.find(params[:id])
    #authorize_action_for(@account)

    AccountUpdater.update(@account, params, user) do |result|
      result.on_success { |account| respond_with_user_and account }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def destroy
    @account = Account.find(params[:id])
    #authorize_action_for(@account)

    AccountDeleter.delete(@account, user) do |result|
      result.on_success { |account| respond_with_user_and account, status: 204 }
      result.on_error   { |account| respond_with_user_and account, status: 422 }
    end
  end

  def global_data
    AccountSearcher.get_global_data(
      current_account,
      current_tenant,
      current_tenant_user,
      params
    ) do |result|
      result.on_success { |global_data| respond_with_user_and global_data, represent_with: GlobalDataRepresenter, status: 200 }
      result.on_error { |global_data| respond_with_user_and global_data, status: 422 }
    end
  end

  def dashboard_global_data
    AccountSearcher.get_dashboard_global_data(
      current_account,
      current_tenant,
      current_tenant_user,
      params
    ) do |result|
      result.on_success { |global_data| respond_with_user_and global_data, represent_with: DashboardGlobalDataRepresenter, status: 200 }
      result.on_error { |global_data| respond_with_user_and global_data, status: 422 }
    end
  end

  def error_adapters_detail
    AccountSearcher.get_error_adapters_detail(
      current_account,
      current_tenant
    ) do |result|
      result.on_success { |error_adapters_detail_data| respond_with_user_and error_adapters_detail_data, represent_with: ErrorAdaptersDetailRepresenter, status: 200 }
      result.on_error { |error_adapters_detail_data| respond_with_user_and error_adapters_detail_data, status: 422 }
    end
  end

  def register_card
    @account = current_account

    CardCreator.register_card(params, current_organisation, user) do |result|
      result.on_success { |card| respond_with_user_and card, represent_with: CreditCardRepresenter, status: 200 }
      result.on_error   { |errors| render status: 500, json: { errors: errors } }
    end
  end

  def get_cards
    @account = current_account
    @cards = @account.credit_cards

    respond_with @cards, represent_with: CreditCardsRepresenter, status: 200
  end

  def get_invoice_report
    InvoiceSearcher.get_invoice_report(current_account) do |result|
      result.on_success { |invoices| respond_with invoices, represent_with: InvoicesRepresenter, status: 200 }
      result.not_found  { render body: nil, status: 404 }
    end
  end

  def refetch_iam_adapters
    AdapterCreator.refetch_iam_adapters(current_account) do |result|
       result.on_success { render body: nil, status: 200 }
       result.on_error  { render body: nil, status: 422 }
    end
  end

  def generate_service_reports
    @account = current_account

    xls_name = AccountService.generate_service_report(@account)

    file_path = Rails.root.join('public', xls_name)
    system "sudo touch #{file_path} && chown cloudstreet:cloudstreet #{file_path}"
    render json:{path: "accounts/download_service_report?name=#{xls_name}"}, status: 200   
  end

  def download_service_report
    file_path = Rails.root.join('public',"#{params['name']}")
    render json: { message: "Not Found" }, status: 404 and return if params['name'].nil? || !File.exist?(file_path)
    tries = 3
    begin
      File.open(file_path, 'rb')  do |f|
        send_data f.read, filename: params['name'], type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", :disposition => "attachment"
      end
    rescue Errno::ENOENT => e
      tries -= 1
      sleep 3
      if tries > 0
        retry
      else
        CSLogger.info "File doesn't exist."
      end
    end
    system "sudo rm #{file_path}"
  end

  def report_notification
    ReportService.notifier(params) do |result|
      result.on_success { render json: :nothing, status: :ok }
    end
  end

  def get_saas_subscriptions
    @account = current_account
    authorize_action_for(Account)
    AWSMarketplaceSaasSubscription::MarketplaceMeteringService.register(params[:registration_token], @account) if (params[:registration_token].present? && !params[:registration_token].nil?)
    @saas_subscriptions = @account.saas_subscriptions
    respond_with_user_and @saas_subscriptions, payment_access_right: user.is_permission_granted?("cs_settings_financial_edit"), represent_with: AWSMarketplaceSaasSubscriptionsRepresenter, status: 200
  end

  def favorite_report_notification
    FavoriteReportService.notifier(params) do |result|
      result.on_success { render json: :nothing, status: :ok }
    end
  end

  private
  def account_params
    params.permit(:name, :email)
  end

  def restrict_ami_application
    if ENV["SAAS_ENV"].eql?('false')
      render json: { error: I18n.t("unavailable_action_for_this_environment") }, status: 412
    end
  end
end
