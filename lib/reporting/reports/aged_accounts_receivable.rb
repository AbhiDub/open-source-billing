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
  module Reports
    class AgedAccountsReceivable < Reporting::Report
      def initialize(options={})
        #raise "debugging...#{options[:report_criteria].to_date}"
        @report_name = options[:report_name] || "no report"
        @report_criteria = options[:report_criteria]
        @report_data = get_report_data
        calculate_report_totals
      end

      class ReportData
        attr_accessor :client_name, :invoice_total, :zero_to_thirty, :thirty_one_to_sixty, :sixty_one_to_ninety, :ninety_one_and_above
      end

      def period
        "As of #{@report_criteria.to_date}"
      end

      def get_report_data
        # Report columns: Client, 0_30, 31_60, 61_90, Over_90
        aged_invoices = Invoice.find_by_sql(<<-eos
          SELECT aged.client_name,aged.currency_id,aged.currency_code,
            SUM(CASE WHEN aged.age BETWEEN 0 AND 30 THEN aged.invoice_total - aged.payment_received ELSE 0 END) AS zero_to_thirty,
            SUM(CASE WHEN aged.age BETWEEN 31 AND 60 THEN aged.invoice_total - aged.payment_received ELSE 0 END) AS thirty_one_to_sixty,
            SUM(CASE WHEN aged.age BETWEEN 61 AND 90 THEN aged.invoice_total - aged.payment_received ELSE 0 END) AS sixty_one_to_ninety,
            SUM(CASE WHEN aged.age > 90 THEN aged.invoice_total - aged.payment_received ELSE 0 END) AS ninety_one_and_above,
            0 AS client_total
          FROM (
            SELECT
              case when clients.organization_name = '' then CONCAT(clients.first_name,' ',clients.last_name) else clients.organization_name  end AS client_name,
              invoices.invoice_total,
              IFNULL(SUM(payments.payment_amount), 0) payment_received,
              DATEDIFF('#{@report_criteria.to_date}', DATE(IFNULL(invoices.due_date, invoices.invoice_date))) age,
              invoices.`status`,
              IFNULL(currencies.code,'$') as currency_code,
              IFNULL(invoices.currency_id,0) as currency_id,
              invoices.id as id
            FROM `invoices`
              LEFT JOIN `currencies` ON `currencies`.`id` = `invoices`.`currency_id`
              INNER JOIN `clients` ON `clients`.`id` = `invoices`.`client_id`
              LEFT JOIN `payments` ON `invoices`.`id` = `payments`.`invoice_id` AND (payments.payment_date <= '#{@report_criteria.to_date}') AND (`payments`.`deleted_at` IS NULL)
            WHERE
              (`invoices`.`deleted_at` IS NULL)
              AND (DATE(IFNULL(invoices.due_date, invoices.invoice_date)) <= '#{@report_criteria.to_date}')
              AND (invoices.`status` != "paid")
              #{@report_criteria.client_id == 0 ? "" : "AND invoices.client_id = #{@report_criteria.client_id}"}
            GROUP BY clients.organization_name,  invoices.invoice_total, invoices.`status`, invoices.invoice_number
          ) AS aged
          GROUP BY aged.client_name,aged.currency_id
        eos
        )
        aged_invoices
      end

      def calculate_report_totals
        @report_total = []
        # display client name in only first row
        @report_data.group_by{|x| x['client_name']}.values.each do |row|
          index =0
          row.map{|x| x.border=0}
          row.last.border=1
          row.map{|x| index==0 ? index=1 : x["client_name"] = ""}
        end
        @report_data.group_by{|x| x['currency_id']}.values.each do |row|
          total = Hash.new(0)
          total["zero_to_thirty"] += row.map{|x| x["zero_to_thirty"]}.sum
          total["thirty_one_to_sixty"] += row.map{|x| x["thirty_one_to_sixty"]}.sum
          total["sixty_one_to_ninety"] += row.map{|x| x["sixty_one_to_ninety"]}.sum
          total["ninety_one_and_above"] += row.map{|x| x["ninety_one_and_above"]}.sum
          total["total_amount"] =  total["zero_to_thirty"] + total["thirty_one_to_sixty"] + total["sixty_one_to_ninety"] + total["ninety_one_and_above"]
          total["currency_code"] = row.first["currency_code"]
          @report_total << total
        end
      end

      def to_csv
        aged_accounts_receivable_csv self
      end

      def aged_accounts_receivable_csv report
        headers =['Client Name', '0-30 days', '31-60 days', '61-90 days', '90+ days', 'Client Total AR']
        CSV.generate do |csv|
          csv << headers
          report.report_data.each do |item|
            temp_row=[
                item.client_name.to_s,
                item.zero_to_thirty.to_f.round(2),
                item.thirty_one_to_sixty.to_f.round(2),
                item.sixty_one_to_ninety.to_f.round(2),
                item.ninety_one_and_above.to_f.round(2),
                (item.zero_to_thirty.to_f + item.thirty_one_to_sixty.to_f + item.sixty_one_to_ninety.to_f +  item.ninety_one_and_above.to_f).round(2),

            ]
            csv << temp_row
          end
          is_first = true
          report.report_total.each do |total|
            row_total = ["#{is_first ? 'Total' : '' }",
                         total["zero_to_thirty"].to_i,
                         total["thirty_one_to_sixty"].to_f.round(2),
                         total["sixty_one_to_ninety"].to_f.round(2),
                         total["ninety_one_and_above"].to_f.round(2),
                         total["total_amount"].to_f.round(2)
            ]
            is_first=false
            csv << row_total
          end
        end
      end

      def to_xlsx
        aged_accounts_receivable_xlsx self
      end

      def aged_accounts_receivable_xlsx report
        headers =['Client Name', '0-30 days', '31-60 days', '61-90 days', '90+ days', 'Client Total AR']
        doc = XlsxWriter.new
        doc.quiet_booleans!
        sheet1 = doc.add_sheet("Aged Accounts Receivable")

        unless report.report_data.blank?
          sheet1.add_row(headers)
          report.report_data.each do |item|
            temp_row=[
                item.client_name.to_s,
                item.zero_to_thirty.to_f.round(2),
                item.thirty_one_to_sixty.to_f.round(2),
                item.sixty_one_to_ninety.to_f.round(2),
                item.ninety_one_and_above.to_f.round(2),
                (item.zero_to_thirty.to_f + item.thirty_one_to_sixty.to_f + item.sixty_one_to_ninety.to_f +  item.ninety_one_and_above.to_f).round(2),

            ]
            sheet1.add_row(temp_row)
          end
          is_first = true
          report.report_total.each do |total|
            row_total = ["#{is_first ? 'Total' : '' }",
                         total["zero_to_thirty"].to_i,
                         total["thirty_one_to_sixty"].to_f.round(2),
                         total["sixty_one_to_ninety"].to_f.round(2),
                         total["ninety_one_and_above"].to_f.round(2),
                         total["total_amount"].to_f.round(2)
            ]
            is_first=false
            sheet1.add_row(row_total)
          end
        else
          sheet1.add_row([' ', "No data found against the selected criteria. Please change criteria and try again."])
        end
        doc
      end
    end
  end
end