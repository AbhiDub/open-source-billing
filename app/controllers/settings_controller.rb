class SettingsController < ApplicationController
  def create
    user = current_user
    @language_changed = false
    if params[:multi_currency].present?
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
    if params[:locale].present?
      user.settings.language = params[:locale]
      @language_changed = true
    end
    if params[:default_currency].present?
      user.settings.default_currency = params[:default_currency]
    end
    respond_to { |format| format.js }
  end

  def index
    @email_templates = EmailTemplate.unscoped
  end

  def set_default_currency
    currency = Currency.find(params[:currency_id]) rescue Currency.default_currency
    current_user.settings.default_currency = currency.unit
    #render text: true
  end
end
