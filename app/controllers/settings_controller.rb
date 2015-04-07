class SettingsController < ApplicationController
  def create
      user = current_user
    if params[:currency_select].present?
      user.settings.currency = "On"
      respond_to { |format| format.js }
    else
      user.settings.currency = "Off"
      respond_to { |format| format.js }
    end
    if params[:date_format].present?
      user.settings.date_format = params[:date_format]
    end
    if params[:lines_per_page].present?
      user.settings.lines_per_page = params[:lines_per_page]
    end
  end
end
