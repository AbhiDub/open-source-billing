class SubUsersController < ApplicationController
  load_and_authorize_resource :user, :only => [:index, :show, :create, :destroy, :update, :new, :edit]

  helper_method :sort_column, :sort_direction

  def index
    @sub_users = params[:search].present? ? User.search(params[:search]).records.order(sort_column + " " + sort_direction) : User.order(sort_column + " " + sort_direction)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @sub_user = User.new()
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    sub_user = User.new({user_name: params[:user_name], email: params[:email],
                         password: params[:password],
                         password_confirmation: params[:password_confirmation]
                        })

    sub_user.account_id = current_user.account_id if User.method_defined?(:account_id)
    sub_user.role_ids = params[:role_ids]
    # skip email confirmation for login
    sub_user.skip_confirmation!
    respond_to do |format|
      if sub_user.already_exists?(params[:email])
        redirect_to(sub_users_url, alert: 'User with same email already exists.')
        return
      elsif sub_user.save
        # assign current user's company to newly created user
        sub_user.update(current_company: get_company_id)
        current_user.accounts.first.users << sub_user
        begin
          UserMailer.new_user_account(current_user, sub_user).deliver if params[:notify_user]
        rescue => e
          puts  e
        end
        redirect_to(sub_users_url, notice: 'User has been saved successfully')
        return
      else
        format.html { render action: 'new', alert: 'Failed to save user. Make sure you have entered correct record' }
      end
    end
  end

  def edit
    @sub_user = User.find_by_id(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    sub_user = User.find(params[:user_id])
    respond_to do |format|
      options = {user_name: params[:user_name], email: params[:email],
                 password: params[:password], password_confirmation: params[:password]}

      # don't update password if not provided
      if params[:password].blank?
        options.delete(:password)
        options.delete(:password_confirmation)
      end

      message = if sub_user.update_attributes(options)
                  sub_user.role_ids = params[:role_ids] if params[:role_ids].present?
                  {notice: 'User has been updated successfully'}
                else
                  {alert: 'User can not be updated'}
                end

      redirect_to(sub_users_url, message)
      return
    end
  end

  def destroy
    sub_user = User.find_by_id(params[:id]).destroy
    respond_to { |format| format.js }
  end

  def user_settings
  end

  private
  def sort_column
    params[:sort] ||= 'user_name'
    User.column_names.include?(params[:sort]) ? params[:sort] : 'user_name'
  end

  def sort_direction
    params[:direction] ||= 'desc'
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
