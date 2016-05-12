class ImportDataController < ApplicationController
  def index

  end

  def import_freshbooks_data
    if params[:freshbooks][:account_url].blank? and  params[:freshbooks][:api_token].blank?
      redirect_to import_data_path, alert: "Please provide freshbooks account url and api key"
    else
      company_ids = ::Company.pluck(:id)
      freshbooks_client = FreshBooks::Client.new(params[:freshbooks][:account_url], params[:freshbooks][:api_token])
      client_response = Services::ImportClientsService.new.import_data(freshbooks_client,company_ids) if params[:freshbooks][:data_filters].include?("client")
      tax_response = Services::ImportTaxService.new.import_data(freshbooks_client) if params[:freshbooks][:data_filters].include?("tax")
      item_response = Services::ImportItemService.new.import_data(freshbooks_client, company_ids) if params[:freshbooks][:data_filters].include?("item")
      task_response = Services::ImportTaskService.new.import_data(freshbooks_client, company_ids) if params[:freshbooks][:data_filters].include?("task")

      if client_response and client_response.keys.include?("error")
        redirect_to import_data_path, alert: "#{client_response['code']} : #{client_response['error'] }"
      elsif tax_response and tax_response.keys.include?("error")
        redirect_to import_data_path, alert: "#{tax_response['code']} : #{tax_response['error'] }"
      elsif item_response and item_response.keys.include?("error")
        redirect_to import_data_path, alert: "#{item_response['code']} : #{item_response['error'] }"
      elsif task_response and task_response.keys.include?("error")
        redirect_to import_data_path, alert: "#{task_response['code']} : #{task_response['error'] }"
      else
        redirect_to import_data_path, notice: "#{params[:freshbooks][:data_filters].join(",")} successfully imported"
      end
    end

  end

end
