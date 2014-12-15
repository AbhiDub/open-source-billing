class RecurringProfile < ActiveRecord::Base

  #scope
  scope :multiple, lambda { |ids_list| where("id in (?)", ids_list.is_a?(String) ? ids_list.split(',') : [*ids_list]) }
  scope :archive_multiple, lambda { |ids| multiple(ids).map(&:archive) }
  scope :delete_multiple, lambda { |ids| multiple(ids).map(&:destroy) }

  #attr
  #attr_accessible :client_id, :discount_amount, :discount_percentage, :notes, :po_number, :status, :sub_total, :tax_amount, :terms, :first_invoice_date, :frequency, :occurrences, :prorate, :prorate_for, :gateway_id, :created_at, :updated_at, :invoice_number, :discount_type, :invoice_total, :archive_number, :archived_at, :deleted_at, :payment_terms_id, :company_id, :last_invoice_status, :recurring_profile_line_items_attributes, :last_sent_date, :sent_invoices

  #associations
  belongs_to :client
  belongs_to :payment_term
  belongs_to :company
  has_many :recurring_profile_line_items, :dependent => :destroy

  accepts_nested_attributes_for :recurring_profile_line_items, :reject_if => proc { |line_item| line_item['item_id'].blank? }, :allow_destroy => true

  paginates_per 10

  # callbacks
  before_create :set_profile_id

  # archive and delete
  acts_as_archival
  acts_as_paranoid

  # get an auto generated profile id
  def set_profile_id
    self.invoice_number = RecurringProfile.get_next_profile_id
  end

  #remaining invoices to be sent
  def remaining_occurrences
    occurrences.to_i == 0 ? "infinite" : occurrences.to_i - (sent_invoices.to_i || 0)
  end

  def send_more?
    (occurrences.to_i - sent_invoices.to_i > 0 || occurrences.to_i == 0) ? true : false
  end

  def is_currently_sent?
    self.first_invoice_date == Date.today ? true : false
  end

  def self.get_next_profile_id
    ((with_deleted.maximum("id") || 0) + 1).to_s.rjust(5, "0")
  end

  def tax_details
    taxes = []
    tax_list = Hash.new(0)
    recurring_profile_line_items.each do |li|
      next unless [li.item_unit_cost, li.item_quantity].all?
      line_total = li.item_unit_cost * li.item_quantity
      # calculate tax1 and tax2
      taxes.push({name: li.tax1.name, pct: "#{li.tax1.percentage.to_s.gsub('.0', '')}%", amount: (line_total * li.tax1.percentage / 100.0)}) unless li.tax1.blank?
      taxes.push({name: li.tax2.name, pct: "#{li.tax2.percentage.to_s.gsub('.0', '')}%", amount: (line_total * li.tax2.percentage / 100.0)}) unless li.tax2.blank?
    end

    taxes.each do |tax|
      tax_list["#{tax[:name]} #{tax[:pct]}"] += tax[:amount]
    end
    tax_list
  end

  def self.filter(params, per_page)
    mappings = {active: 'unarchived', archived: 'archived', deleted: 'only_deleted'}
    method = mappings[params[:status].to_sym]
    self.send(method).page(params[:page]).per(per_page)
  end

  def self.recover_archived ids
    multiple(ids).map(&:unarchive)
  end

  def self.recover_deleted ids
    multiple(ids).only_deleted.each { |profile| profile.recover; profile.unarchive }
  end

end
