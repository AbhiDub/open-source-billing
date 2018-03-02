class Osbm::AdminsController < ApplicationController
  layout 'osbm/application'
  before_filter :check_subdomain
  def accounts
    @accounts = Account.all
  end

  def new_account
    @account = Account.new
  end

  def create_account
    @account_already = Account.find_by org_name: params[:account][:org_name]
    if @account_already.present?
      @notice = "Account with company name '#{params[:account][:org_name]}' already exists!"
    else
      @account = Account.find_or_create_by(org_name: params[:account][:org_name])
      @notice = "Account with company name '#{params[:account][:org_name]}' created successfully."
    end
  end

  def users
    @users = User.unscoped
  end

  def plans
    @plans = Plan.unscoped
  end

  private
  def check_subdomain
    redirect_to main_app.root_path unless request.subdomain == 'admin'
  end
end