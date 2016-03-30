# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->


#  Calculate the line total for invoice
  updateLineTotal = (elem) ->
    container = elem.parents("tr.fields")
    cost = jQuery(container).find("input.cost").val()
    qty = jQuery(container).find("input.qty").val()
    cost = 0 if not cost? or cost is "" or not jQuery.isNumeric(cost)
    qty = 0 if not qty? or qty is "" or not jQuery.isNumeric(qty)
    line_total = ((parseFloat(cost) * parseFloat(qty))).toFixed(2)
    jQuery(container).find(".line_total").text(line_total)

  # Calculate grand total from line totals
  updateInvoiceTotal = ->
    total = 0
    tax_amount = 0
    discount_amount = 0
    jQuery("table.log_invoice_grid_fields tr:visible .line_total").each ->
      line_total = parseFloat(jQuery(this).text())
      total += line_total
      #update invoice sub total lable and hidden field
      jQuery("#log_invoice_sub_total, #recurring_profile_sub_total").val(total.toFixed(2))
      jQuery("#log_invoice_sub_total_lbl").text(total.toFixed(2))

      #update invoice total lable and hidden field
      jQuery("#log_invoice_total, #recurring_profile_invoice_total").val(total.toFixed(2))
      jQuery("#log_invoice_total_lbl").text(total.toFixed(2))

    #  tax_amount += applyTax(line_total,jQuery(this))

    discount_amount = applyDiscount(total)
    #console.log(discount_amount)
    #alert(total.toFixed(2))
    #update tax amount label and tax amount hidden field
    #jQuery("#invoice_tax_amount_lbl").text(tax_amount.toFixed(2))
    #jQuery("#invoice_tax_amount, #recurring_profile_tax_amount").val(tax_amount.toFixed(2))

    #update discount amount lable and discount hidden field
    jQuery("#invoice_discount_amount_lbl").text(discount_amount)
    jQuery("#invoice_discount_amount, #recurring_profile_discount_amount").val((discount_amount * -1).toFixed(2))
    #console.log(jQuery("#log_invoice_total_lbl").text())
    total_balance = (parseFloat(jQuery("#log_invoice_total_lbl").text() - discount_amount) + tax_amount)
    #console.log(total_balance)
    jQuery("#log_invoice_total, #recurring_profile_invoice_total").val(total_balance.toFixed(2))
    jQuery("#log_invoice_total_lbl").text(total_balance.toFixed(2))
    jQuery("#log_invoice_total_lbl").formatCurrency({symbol: window.currency_symbol})

  # Apply discount percentage on subtotals
  applyDiscount = (subtotal) ->
    discount_percentage = jQuery("#invoice_discount_percentage").val() #|| jQuery("#recurring_profile_discount_percentage").val()
    discount_type = jQuery("select#discount_type").val()
    #console.log(subtotal*(parseFloat(discount_percentage)/100.0))
    #console.log(discount_type)
    #alert(subtotal)
    discount_percentage = 0 if not discount_percentage? or discount_percentage is ""
    if discount_type == "%" then (subtotal * (parseFloat(discount_percentage) / 100.0)) else discount_percentage

  # Update line and grand total if line item fields are changed
  jQuery("input.cost, input.qty").live "blur", ->
    updateLineTotal(jQuery(this))
    updateInvoiceTotal()

  jQuery("input.cost, input.qty").live "keyup", ->
    updateLineTotal(jQuery(this))
    updateInvoiceTotal()
  #jQuery(this).popover "hide"

  # Update line and grand total when tax is selected from dropdown
  jQuery("select.tax1, select.tax2").live "change", ->
    updateInvoiceTotal()

  # Prevent form submission if enter key is press in cost,quantity or tax inputs.
  jQuery("input.cost, input.qty").live "keypress", (e) ->
    if e.which is 13
      e.preventDefault()
      false

  # Load Items data when an item is selected from dropdown list
  jQuery(".log_invoice_grid_fields select.items_list").live "change", ->
    updateInvoiceTotal()

  # Add empty line item row
#  addLineItemRow = (elem) ->
#    if elem.parents('tr.fields').next('tr.fields:visible').length is 0
#      jQuery(".log_invoice_grid_fields .add_nested_fields").click()
#  #applyChosen(jQuery('.invoice_grid_fields tr.fields:last .chzn-select'))

  jQuery(".log_invoice_grid_fields .add_nested_fields").live "click", ->
    setTimeout "window.applyChosen(jQuery('.log_invoice_grid_fields tr.fields:last .chzn-select'))", 0

  # Re calculate the total invoice balance if an item is removed
  jQuery(".remove_nested_fields").live "click", ->
    setTimeout (->
      updateInvoiceTotal()
    ), 100

  # Subtract discount percentage from subtotal
  jQuery("#invoice_discount_percentage, #recurring_profile_discount_percentage").on "blur keyup", ->
    updateInvoiceTotal()

  # Subtract discount percentage from subtotal
  jQuery("select#discount_type").change ->
    updateInvoiceTotal()

  # Don't allow nagetive value for discount
  jQuery("#invoice_discount_percentage, #recurring_profile_discount_percentage,.qty").keydown (e) ->
    if e.keyCode is 109 or e.keyCode is 13
      e.preventDefault()
      false

  # Don't allow paste and right click in discount field
  jQuery("#invoice_discount_percentage, #recurring_profile_discount_percentage, .qty").bind "paste contextmenu", (e) ->
    e.preventDefault()

  # Add date picker to invoice date , invoice due date and payment date.
  jQuery("#log_invoice_date, #invoice_due_date, .date_picker_class").datepicker
    dateFormat: DateFormats.format()
    beforeShow: (input, inst) ->
      widget = jQuery(inst).datepicker('widget')
      widget.css('margin-left', jQuery(input).outerWidth() - widget.outerWidth())

  # Makes the invoice line item list sortable
  jQuery("#log_invoice_grid_fields tbody").sortable
    handle: ".sort_icon"
    items: "tr.fields"
    axis: "y"

  # Calculate line total and invoice total on page load
  jQuery(".log_invoice_grid_fields tr:visible .line_total").each ->
    updateLineTotal(jQuery(this))
    # dont use decimal points in quantity and make cost 2 decimal points
    container = jQuery(this).parents("tr.fields")
    cost = jQuery(container).find("input.cost")
    qty = jQuery(container).find("input.qty")
    cost.val(parseFloat(cost.val()).toFixed(2)) if cost.val()
    qty.val(parseInt(qty.val())) if qty.val()
  updateInvoiceTotal()

  # dispute popup validation
  jQuery("form.dispute_form").submit ->
    flag = true
    if jQuery("#reason_for_dispute").val() is ""
      applyPopover(jQuery("#reason_for_dispute"),"bottomMiddle","topLeft","Enter reason for dispute")
      flag = false
    flag
  jQuery("#reason_for_dispute").live "keyup", ->
    jQuery(this).qtip("hide")

#  # Validate client, cost and quantity on invoice save
#  jQuery(".project-invoice.form-horizontal").submit ->
#    discount_percentage = jQuery("#invoice_discount_percentage").val() || jQuery("#recurring_profile_discount_percentage").val()
#    discount_type = jQuery("select#discount_type").val()
#    sub_total = jQuery('#invoice_sub_total').val()
#    discount_percentage = 0 if not discount_percentage? or discount_percentage is ""
#    item_rows = jQuery("table#log_invoice_grid_fields tr.fields:visible")
#    flag = true
#    # Check if company is selected
#    if jQuery("#invoice_company_id").val() is ""
#      applyPopover(jQuery("#invoice_company_id_chzn"),"bottomMiddle","topLeft","Select a company")
#      flag = false
#      # Check if client is selected
#    else if jQuery("#invoice_client_id").val() is ""
#      applyPopover(jQuery("#invoice_client_id_chzn"),"bottomMiddle","topLeft","Select a client")
#      flag = false
#      # if currency is not selected
#    else if jQuery("#invoice_currency_id").val() is "" and jQuery("#invoice_currency_id").is( ":hidden" ) == false
#      applyPopover(jQuery("#invoice_currency_id_chzn"),"bottomMiddle","topLeft","Select currency")
#      flag = false
#      # check if invoice date is selected
#    else if jQuery("#log_invoice_date").val() is ""
#      applyPopover(jQuery("#log_invoice_date"),"rightTop","leftMiddle","Select invoice date")
#      flag =false
#    else if jQuery("#log_invoice_date").val() isnt "" and !DateFormats.validate_date(jQuery("#log_invoice_date").val())
#      applyPopover(jQuery("#log_invoice_date"),"rightTop","leftMiddle","Make sure date format is in '#{DateFormats.format()}' format")
#      flag = false
#    else if jQuery("#invoice_due_date").val() isnt "" and !DateFormats.validate_date(jQuery("#invoice_due_date").val())
#      applyPopover(jQuery("#invoice_due_date"),"rightTop","leftMiddle","Make sure date format is in '#{DateFormats.format()}' format")
#      flag = false
#      # Check if payment term is selected
#    else if jQuery("#invoice_payment_terms_id").val() is ""
#      applyPopover(jQuery("#invoice_payment_terms_id_chzn"),"bottomMiddle","topLeft","Select a payment term")
#      flag = false
#      # Check if discount percentage is an integer
#    else if jQuery("input#invoice_discount_percentage").val()  isnt "" and isNaN(jQuery("input#invoice_discount_percentage").val())
#      applyPopover(jQuery("#invoice_discount_percentage"),"bottomMiddle","topLeft","Enter Valid Discount")
#      flag = false
#      # Check if no item is selected
#    else if jQuery("tr.fields:visible").length < 1
#      applyPopover(jQuery("#add_line_item"),"bottomMiddle","topLeft","Add line item")
#      flag = false
#      # Check if item is selected
#    else if item_rows.find("select.items_list option:selected[value='']").length is item_rows.length
#      first_item = jQuery("table#log_invoice_grid_fields tr.fields:visible:first").find("select.items_list").next()
#      applyPopover(first_item,"bottomMiddle","topLeft","Select an item")
#      flag = false
#    else if discount_type == '%' and parseFloat(discount_percentage) > 100.00
#      applyPopover(jQuery("#invoice_discount_percentage"),"bottomMiddle","topLeft","Percentage must be hundred or less")
#      flag = false
#    else if discount_type != '%' and parseFloat(discount_percentage) > parseFloat(sub_total)
#      applyPopover(jQuery("#invoice_discount_percentage"),"bottomMiddle","topLeft","Discount must be less than sub-total")
#      flag = false
#
#      # Item cost and quantity should be greater then 0
#    else
#      jQuery("tr.fields:visible").each ->
#        row = jQuery(this)
#        if row.find("select.items_list").val() isnt ""
#          cost = row.find(".cost")
#          qty =  row.find(".qty")
#          tax1 = row.find("select.tax1")
#          tax2 = row.find("select.tax2")
#          tax1_value = jQuery("option:selected",tax1).val()
#          tax2_value = jQuery("option:selected",tax2).val()
#
#          if not jQuery.isNumeric(cost.val()) and cost.val() isnt ""
#            applyPopover(cost,"bottomLeft","topLeft","Enter valid Item cost")
#            flag = false
#          else hidePopover(cost)
#
#          if not jQuery.isNumeric(qty.val())  and qty.val() isnt ""
#            applyPopover(qty,"bottomLeft","topLeft","Enter valid Item quantity")
#            flag = false
#          else if (tax1_value is tax2_value) and (tax1_value isnt "" and tax2_value isnt "")
#            applyPopover(tax2.next(),"bottomLeft","topLeft","Tax1 and Tax2 should be different")
#            flag = false
#          else hidePopover(qty)
#    flag
#
#
#  applyPopover = (elem,position,corner,message) ->
#    elem.qtip
#      content:
#        text: message
#      show:
#        event: false
#      hide:
#        event: false
#      position:
#        at: position
#      style:
#        tip:
#          corner: corner
#    elem.qtip().show()
#    elem.focus()
#
#  useAsTemplatePopover = (elem,id,client_name) ->
#    elem.qtip
#      content:
#        text: "<a href='/invoices/new/#{id}'>To create new invoice use the last invoice send to '#{client_name}'.</a><span class='close_qtip'>x</span>"
#      show:
#        event: false
#      hide:
#        event: false
#      position:
#        at: "rightTop"
#      style:
#        classes: 'use_as_template'
#        tip:
#          corner: "bottomLeft"
#    elem.qtip().show()
#    qtip = jQuery(".qtip.use_as_template")
#    qtip.css("top",qtip.offset().top - qtip.height())
#    qtip.attr('data-top',qtip.offset().top - qtip.height())
#    elem.focus()
#
#  hidePopover = (elem) ->
#    #elem.next(".popover").hide()
#    elem.qtip("hide")

  # Hide use as template qtip
  jQuery('.use_as_template .close_qtip').live "click", ->
    hidePopover(jQuery("#invoice_client_id_chzn"))

  jQuery("#invoice_client_id_chzn,.chzn-container").live "click", ->
    jQuery(this).qtip("hide")

  jQuery("#add_line_item").live "click",->
    jQuery(this).qtip('hide')

  jQuery(".line_item_qtip").live "change",->
    jQuery(this).qtip('hide')

  # Don't send an ajax request if an item is deselected.
  clearLineTotal = (elem) ->
    container = elem.parents("tr.fields")
    container.find("input.description").val('')
    container.find("input.cost").val('')
    container.find("input.qty").val('')
    container.find("select.tax1,select.tax2").val('').trigger("liszt:updated")
    updateLineTotal(elem)
    updateInvoiceTotal()

  jQuery('#active_links a').live 'click', ->
    jQuery('#active_links a').removeClass('active')
    jQuery(this).addClass('active')

  jQuery(".invoice_action_links input[type=submit]").click ->
    jQuery(this).parents("FORM:eq(0)").find("table.table_listing").find(':checkbox').attr()

  # Load last invoice for client if any
  jQuery("#invoice_client_id").unbind 'change'
  jQuery("#invoice_client_id").change ->
    client_id = jQuery(this).val()
    hidePopover(jQuery("#invoice_client_id_chzn")) if client_id is ""
    jQuery("#last_invoice").hide()
    if not client_id? or client_id isnt ""

      jQuery.get('/clients/'+ client_id + '/default_currency')

      jQuery.ajax '/clients/get_last_invoice',
        type: 'POST'
        data: "id=" + client_id
        dataType: 'html'
        error: (jqXHR, textStatus, errorThrown) ->
          alert "Error: #{textStatus}"
        success: (data, textStatus, jqXHR) ->
          data = JSON.parse(data)
          id = jQuery.trim(data[0])
          client_name = data[1]
          unless id is "no invoice"
            useAsTemplatePopover(jQuery("#invoice_client_id_chzn"),id,client_name)
          else
            hidePopover(jQuery(".hint_text:eq(0)"))

  # Change currency of invoice
  jQuery("#invoice_currency_id").unbind 'change'
  jQuery("#invoice_currency_id").change ->
    currency_id = jQuery(this).val()
    hidePopover(jQuery("#invoice_currency_id_chzn")) if currency_id is ""
    if not currency_id? or currency_id isnt ""
      jQuery.get('/invoices/selected_currency?currency_id='+ currency_id)

  # Autofill due date
  jQuery("#invoice_payment_terms_id").unbind 'change'
  jQuery("#invoice_payment_terms_id").change ->
    number_of_days = jQuery("option:selected",this).attr('number_of_days')
    setDuedate(jQuery("#log_invoice_date").val(),number_of_days)

  jQuery.datepicker.setDefaults
    dateFormat: DateFormats.format()

  # calculate invoice due date
  setDuedate = (invoice_date,term_days) ->
    if term_days? and invoice_date?
      invoice_due_date = DateFormats.add_days_in_formated_date(invoice_date,parseInt(term_days))
      jQuery("#invoice_due_date").val(invoice_due_date)
    else
      jQuery("#invoice_due_date").val("")

  # re calculate invoice due date on invoice date change
  jQuery("#log_invoice_date").change ->
    jQuery(this).qtip("hide") if jQuery(this).qtip()
    term_days = jQuery("#invoice_payment_terms_id option:selected").attr('number_of_days')
    setDuedate(jQuery(this).val(),term_days)

  #set due date on page load
  setDuedate(jQuery("#log_invoice_date").val(),jQuery("#invoice_payment_terms_id option:selected").attr('number_of_days'))

  # Hide placeholder text on focus
  jQuery("input[type=text],input[type=number],input[type=checkbox]",".quick_create_wrapper").live("focus",->
    @dataPlaceholder = @placeholder
    @removeAttribute "placeholder"
  ).live("blur", ->
    @placeholder = @dataPlaceholder
    @removeAttribute "dataPlaceholder"
  ).live "keypress", (e) ->
    if e.which is 13
      e.preventDefault()
      jQuery(".active-form .btn_save").trigger("click")
    hidePopover(jQuery(this))

  # Show quick create popups under create buttons
  jQuery(".quick_create").click ->
    pos = $(this).position()
    height = $(this).outerHeight()
    jQuery('.quick_create_wrapper').hide()
    jQuery("##{jQuery(this).attr('name')}").css(
      position: "absolute"
      top: (pos.top + height) + "px"
      left: pos.left + "px"
    ).show()

  jQuery(".close_btn").live "click", ->
    jQuery(this).parents('.quick_create_wrapper').hide().find("input").qtip("hide")

  # Alert on dispute if invoice is paid
  jQuery('#dispute_link').click ->
    jQuery('#reason_for_dispute').val('')
    flag = true
    status = jQuery(this).attr "value"
    if status is "paid"
      alert "Paid invoice can not be disputed."
      flag = false
    flag

  jQuery(".more").live "click", ->
    jQuery(".toggleable").removeClass("collapse")

  jQuery("#add_line_item").live "click", ->
    options = $('.items_list:first').html()
    $('.items_list:last').html(options).find('option:selected').removeAttr('selected')
    $('.items_list:last').find('option[data-type = "deleted_item"], option[data-type = "archived_item"], option[data-type = "other_company"], option[data-type = "active_line_item"]').remove()
    tax1 = $('.tax1:first').html()
    tax2 = $('.tax2:first').html()
    $('.tax1:last').html(tax1).find('option:selected').removeAttr('selected')
    $('.tax2:last').html(tax2).find('option:selected').removeAttr('selected')
    $('.tax1:last').find('option[data-type = "deleted_tax"], option[data-type = "archived_tax"], option[data-type = "active_line_item_tax"]').remove()
    $('.tax2:last').find('option[data-type = "deleted_tax"], option[data-type = "archived_tax"], option[data-type = "active_line_item_tax"]').remove()


  jQuery(".less").live "click", ->
    jQuery(".toggleable").addClass("collapse")

  #send only email to client on clicking send this note only link.
  jQuery('#send_note_only').click ->
    jQuery.ajax '/invoices/send_note_only',
      type: 'POST'
      data: "response_to_client=" + jQuery("#response_to_client").val() + "&inv_id=" + jQuery("#inv_id").val()
      dataType: 'html'
      error: (jqXHR, textStatus, errorThrown) ->
        alert "Error: #{textStatus}"
      success: () ->
        jQuery('.alert').hide();
        jQuery(".alert.alert-success").show().find("span").html "This note has been sent successfully"