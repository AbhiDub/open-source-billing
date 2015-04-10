class SettingsController < ApplicationController
  def create
    user = current_user
    if params[:currency_select].present?
      user.settings.currency = "On"
    else
      user.settings.currency = "Off"
    end
    if params[:date_format].present?
      user.settings.date_format = params[:date_format]
    end
    if params[:records_per_page].present?
      user.settings.records_per_page = params[:records_per_page]
    end
    respond_to { |format| format.js }
  end
end
