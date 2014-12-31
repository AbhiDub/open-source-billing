#
# Open Source Billing - A super simple software to create & send invoices to your customers and
# collect payments.
# Copyright (C) 2013 Mark Mian <mark.mian@opensourcebilling.org>
#
# This file is part of Open Source Billing.
#
# Open Source Billing is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Open Source Billing is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Open Source Billing.  If not, see <http://www.gnu.org/licenses/>.
#
module Reporting
  module Dashboard
    # get the recent activity - 10 most recent items
    def self.get_recent_activity
      # columns returned: activity type, client, amount, activity date, currency unit, currency code
      # fetch last 10 invoices and payments
      invoices = Invoice.select("id, client_id, currency_id, invoice_total, created_at").order("created_at DESC").limit(5)
      payments = Payment.select("payments.id, clients.organization_name, payments.payment_amount, payments.created_at, invoice_id").includes(:invoice => :client).joins(:invoice => :client).order("payments.created_at DESC").limit((10 - invoices.length))

      # merge invoices and payments in activity array
      recent_activity = []
      invoices.each { |inv| recent_activity << {:activity_type => "invoice", :activity_action => "sent to", :client => (inv.client.organization_name rescue ''), :amount => inv.invoice_total, :unit => (inv.currency.present? ? inv.currency.unit : "$"), :code => (inv.currency.present? ? inv.currency.code : "USD"), :activity_date => inv.created_at, :activity_path => "/invoices/#{inv.id}/edit"} }
      payments.each { |pay| recent_activity << {:activity_type => "payment", :activity_action => "received from", :client => (pay.invoice.client.organization_name rescue ''), :amount => pay.payment_amount, :unit => (pay.invoice.currency.present? ? pay.invoice.currency.unit : "$"), :code => (pay.invoice.currency.present? ? pay.invoice.currency.code : "USD"), :activity_date => pay.created_at, :activity_path => "/payments/#{pay.id}/edit"} }

      # sort them by created_at in descending order
      recent_activity.sort{ |a, b| b[:activity_date] <=> a[:activity_date] }
    end

    # get chart data
    def self.get_chart_data(currency=nil)
      # month, invoices amount, payments amount
      number_of_months = 6
      chart_months = {}
      chart_years = []
      chart_ticks = []
      start_date = (number_of_months * -1).months.from_now.to_date.at_beginning_of_month
      end_date = Date.today.at_end_of_month
      # build a hash of months with nil amounts
      number_of_months.times do |i|
        chart_months[(start_date + (i+1).month).month] = nil
        chart_years << (start_date + (i+1).month).year
      end


      # invoices amount group by month for last *number_of_months* months
      currency_filter = currency.nil? ? "" : "currency_id=#{currency.id}"
      invoices = Invoice.group("month(invoice_date)").where(:invoice_date => start_date..end_date).where(currency_filter).sum("invoice_total")
      # TODO: credit amount handling
      #payments = Payment.group("month(payment_date)").where(:payment_date => start_date..end_date).sum("payment_amount")
      payments = Payment.where(:payment_date => start_date..end_date).where("payment_type is null or payment_type != ?",'credit').group("month(payment_date)").sum("payment_amount")

      chart_data = {}
      chart_data[:invoices] = chart_months.merge(invoices).map { |month, amount| amount.to_f }
      chart_data[:payments] = chart_months.merge(payments).map { |month, amount| amount.to_f }
      chart_months = chart_months.map { |month, amount| Date::ABBR_MONTHNAMES[month] }
      chart_months.length.times {|i| chart_ticks << "#{chart_months[i]}, #{chart_years[i]}"}
      chart_data[:ticks] = chart_ticks #chart_months.map { |month, amount| Date::ABBR_MONTHNAMES[month] }
      chart_data
    end

    # get outstanding invoices
    def self.get_outstanding_invoices
      Invoice.total_invoices_amount - Payment.total_payments_amount
    end

    def self.get_ytd_income
      ytd = 0
       Invoice.where(invoice_date: Date.today.beginning_of_year..Date.today).each do |invoice|
        ytd += invoice.payments.sum(:payment_amount).to_f
       end
      ytd
    end

    def self.get_aging_data(currency=nil)
      aged_invoices = Invoice.find_by_sql(<<-eos
          SELECT zero_to_thirty, thirty_one_to_sixty, sixty_one_to_ninety, ninety_one_and_above
          FROM (
            SELECT
              SUM(CASE WHEN aged.age BETWEEN 0 AND 30 THEN aged.invoice_total - aged.payment_received ELSE 0 END) AS zero_to_thirty,
              SUM(CASE WHEN aged.age BETWEEN 31 AND 60 THEN aged.invoice_total - aged.payment_received ELSE 0 END) AS thirty_one_to_sixty,
              SUM(CASE WHEN aged.age BETWEEN 61 AND 90 THEN aged.invoice_total - aged.payment_received ELSE 0 END) AS sixty_one_to_ninety,
              SUM(CASE WHEN aged.age > 90 THEN aged.invoice_total - aged.payment_received ELSE 0 END) AS ninety_one_and_above,
              0 AS client_total
            FROM (
              SELECT
                clients.organization_name AS client_name,
                invoices.invoice_total,
                IFNULL(SUM(payments.payment_amount), 0) payment_received,
                DATEDIFF('#{Date.today}', DATE(IFNULL(invoices.due_date, invoices.invoice_date))) age,
                invoices.`status`
              FROM `invoices`
                INNER JOIN `clients` ON `clients`.`id` = `invoices`.`client_id`
                LEFT JOIN `payments` ON `invoices`.`id` = `payments`.`invoice_id` AND (payments.payment_date <= '#{Date.today}') AND (`payments`.`deleted_at` IS NULL)
              WHERE
                (`invoices`.`deleted_at` IS NULL)
                AND (DATE(IFNULL(invoices.due_date, invoices.invoice_date)) <= '#{Date.today}')
                AND (invoices.`status` != "paid")
              GROUP BY clients.organization_name,  invoices.invoice_total, invoices.`status`, invoices.invoice_number
            ) AS aged
          ) total_aged
      eos
      ).first
    end

    def self.get_chart_details(options)
      chart_date = Date.parse options[:chart_date]

      if options[:chart_for] == 'invoices'
        Invoice.where(:invoice_date => chart_date..chart_date.at_end_of_month).order('created_at DESC')
      else
        Payment.where(:payment_date => chart_date..chart_date.at_end_of_month).where("payment_type is null or payment_type != ?",'credit').order('created_at DESC')
      end
    end

  end
end