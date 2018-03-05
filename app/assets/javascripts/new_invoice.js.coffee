class @Invoice

  applyDatePicker = ->
    $('#invoice_date_picker').pickadate
      format: "yyyy-mm-dd"
      formatSubmit: DateFormats.format()
      onSet: (context) ->
        value = @get('value')
        $('#invoice_date').html value
        $('#invoice_invoice_date').val value
        $('#next_invoice_date').html value
        $('#invoice_recurring_schedule_attributes_next_invoice_date').val value

    $('#invoice_due_date_picker').pickadate
      format: "yyyy-mm-dd"
      formatSubmit: DateFormats.format()
      onSet: (context) ->
        value = @get('value')
        $('#invoice_due_date_text').html value
        $('#invoice_due_date').val value

    $("#next_invoice_date_picker").pickadate
      format: "yyyy-mm-dd"
      formatSubmit: DateFormats.format()
      onSet: (context) ->
        value = @get('value')
        $('#next_invoice_date').html value
        $('#invoice_recurring_schedule_attributes_next_invoice_date').val value

  # Calculate the line total for invoice
  updateLineTotal = (elem) ->
    container = elem.parents("tr.fields")
    cost = $(container).find("input.cost").val()
    qty = $(container).find("input.qty").val()
    cost = 0 if not cost? or cost is "" or not $.isNumeric(cost)
    qty = 0 if not qty? or qty is "" or not $.isNumeric(qty)
    line_total = ((parseFloat(cost) * parseFloat(qty))).toFixed(2)
    $(container).find(".line_total").text(line_total)

  # Calculate grand total from line totals
  updateInvoiceTotal = ->
    total = 0
    tax_amount = 0
    discount_amount = 0
    invoice_tax_amount = 0.0
    $('table.invoice_grid_fields tr:visible .line_total').each ->
      line_total = parseFloat($(this).text())
      total += line_total
      $('#invoice_sub_total').val total.toFixed(2)
      $('#invoice_sub_total_lbl').text total.toFixed(2)
      $('#invoice_invoice_total').val total.toFixed(2)
      $('#invoice_total_lbl').text total.toFixed(2)
      $('.invoice_total_strong').html total.toFixed(2)
      tax_amount += applyTax(line_total, $(this))
    discount_amount = applyDiscount(total)

    $('#tax_amount_lbl').text tax_amount.toFixed(2)
    $('#invoice_tax_amount').val tax_amount.toFixed(2)
    $('#invoice_discount_amount_lbl').text discount_amount.toFixed(2)
    $('#invoice_discount_amount').val (discount_amount * -1).toFixed(2)
    total_balance = parseFloat($('#invoice_total_lbl').text() - discount_amount) + tax_amount

    if $('#invoice_tax_id').val() != ""
      invoice_tax_amount = getInvoiceTax(total_balance).toFixed(2)
      $("#invoice_invoice_tax_amount").val invoice_tax_amount
    else
      $("#invoice_invoice_tax_amount").val invoice_tax_amount

    invoice_tax_amount = parseFloat(invoice_tax_amount)
    total_balance += invoice_tax_amount
    $('#invoice_invoice_total').val total_balance.toFixed(2)
    $('#invoice_total_lbl').text total_balance.toFixed(2)
    $('.invoice_total_strong').html total_balance.toFixed(2)
    $('#invoice_total_lbl').formatCurrency symbol: window.currency_symbol

    window.taxByCategory()

  getInvoiceTax = (total) ->
    tax_percentage = parseFloat($("#invoice_tax_id option:selected").data('tax_percentage'))
    total * (parseFloat(tax_percentage) / 100.0)

  # Apply Tax on totals
  applyTax = (line_total,elem) ->
    tax1 = elem.parents("tr").find("select.tax1 option:selected").attr('data-tax_1')
    tax2 = elem.parents("tr").find("select.tax2 option:selected").attr('data-tax_2')
    tax1 = 0 if not tax1? or tax1 is ""
    tax2 = 0 if not tax2? or tax2 is ""
    # if line total is 0
    tax1=tax2=0 if line_total is 0
    discount_amount = applyDiscount(line_total)
    total_tax = (parseFloat(tax1) + parseFloat(tax2))
    (line_total - discount_amount) * (parseFloat(total_tax) / 100.0)

  # Apply discount percentage on subtotals
  applyDiscount = (subtotal) ->
    discount_percentage = $("#invoice_discount_percentage").val()
    discount_type = $("select#discount_type").val()
    discount_percentage = 0 if not discount_percentage? or discount_percentage is ""
    if discount_type == "%" then (subtotal * (parseFloat(discount_percentage) / 100.0)) else discount_percentage

  updateLineTotal = (elem) ->
    container = elem.parents('tr.fields')
    cost = $(container).find('input.cost').val()
    qty = $(container).find('input.qty').val()
    if cost == null or cost == '' or !$.isNumeric(cost)
      cost = 0
    if qty == null or qty == '' or !$.isNumeric(qty)
      qty = 0
    line_total = (parseFloat(cost) * parseFloat(qty)).toFixed(2)
    $(container).find('.line_total').text line_total

  clearLineTotal = (elem) ->
    container = elem.parents('tr.fields')
    container.find('input.description').val ''
    container.find('input.cost').val ''
    container.find('input.qty').val ''
    container.find('select.tax1,select.tax2').val('').trigger 'liszt:updated'
    updateLineTotal elem
    updateInvoiceTotal

  addLineItemRow = (elem) ->
    if elem.parents('tr.fields').next('tr.fields:visible').length == 1
      $('.invoice_grid_fields .add_nested_fields').click()

  empty_tax_fields = (tax_container) ->
    tax_container.find('input.tax1').val ''
    tax_container.find('input.tax2').val ''
    tax_container.find('td.tax1').html ''
    tax_container.find('td.tax1').html ''
    $('.taxes_total').remove()

  @change_invoice_item  = ->
    $('.invoice_grid_fields select.items_list').on 'change', ->
      hidePopover($("table#invoice_grid_fields tr.fields:visible:first"));
      elem = undefined
      elem = $(this)
      if elem.val() == ''
        clearLineTotal elem
        false
      else
        #addLineItemRow(elem);
        $.ajax '/items/load_item_data',
          type: 'POST'
          data: 'id=' + $(this).val()
          dataType: 'html'
          error: (jqXHR, textStatus, errorThrown) ->
            alert 'Error: ' + textStatus
          success: (data, textStatus, jqXHR) ->
            item = JSON.parse(data)
            container = elem.parents('tr.fields')
            container.find('input.description').val item[0]
            container.find('td.description').html item[0]
            container.find('input.cost').val item[1].toFixed(2)
            container.find('td.cost').html item[1].toFixed(2)
            container.find('input.qty').val item[2]
            container.find('td.qty').html item[2]
            empty_tax_fields(container)
            if item[3] != 0
              container.find('input.tax1').val item[3]
              container.find('td.tax1').html item[6]
            if item[4] != 0
              container.find('input.tax2').val item[4]
              container.find('td.tax2').html item[7]
            container.find('input.item_name').val item[5]
            updateLineTotal elem
            updateInvoiceTotal()

  setDuedate = (invoice_date, term_days) ->
    if term_days != null and invoice_date != null
      invoice_due_date = DateFormats.add_days_in_formated_date(invoice_date, parseInt(term_days))
      $('#invoice_due_date_text').html invoice_due_date
      $('#invoice_due_date').val invoice_due_date
    else
      $('#invoice_due_date').val ''

  applyPopover = (elem,position,corner,message) ->
    console.log message
    elem.qtip
      content:
        text: message
      show:
        event: false
      hide:
        event: false
      position:
        at: position
      style:
        tip:
          corner: corner
    elem.qtip().show()
    elem.focus()

  useAsTemplatePopover = (elem,id,client_name) ->
    elem.qtip
      content:
        text: "<a href='/en/invoices/new/#{id}'>To create new invoice use the last invoice sent to '#{client_name}'.</a><span class='close_qtip'>x</span>"
      show:
        event: false
      hide:
        event: false
      position:
        at: "rightTop"
      style:
        classes: 'use_as_template'
        tip:
          corner: "bottomLeft"
    elem.qtip().show()
    qtip = $(".qtip.use_as_template")
    qtip.css("top",qtip.offset().top - qtip.height())
    qtip.attr('data-top',qtip.offset().top - qtip.height())
    elem.focus()

  hidePopover = (elem) ->
    #elem.next(".popover").hide()
    elem.qtip("hide")

  @changeTax = ->
    $('select.tax1, select.tax2').on 'change', ->
      hidePopover($('.select-wrapper.tax2'));
      updateInvoiceTotal()

  @load_functions = ->

    if $('#recurring').is(":checked")
      $("#invoice_recurring_schedule_attributes__destory").val true
    else
      $("#invoice_recurring_schedule_attributes__destory").val false

    $('#recurring').on 'click', ->
      if $(this).is(":checked")
        $("#recurring_schedule_container").removeClass('hide_visibility')
        $("#invoice_recurring_schedule_attributes__destory").val false
      else
        $("#recurring_schedule_container").addClass('hide_visibility')
        $("#invoice_recurring_schedule_attributes__destory").val true

    # Update line and grand total if line item fields are changed
    jQuery("input.cost, input.qty").on "blur", ->
      updateLineTotal(jQuery(this))
      updateInvoiceTotal()

    jQuery("input.cost, input.qty").on "keyup", ->
      updateLineTotal(jQuery(this))
      updateInvoiceTotal()


    $('.modal').modal complete: ->
      $('.qtip').remove()

    applyDatePicker();
    $('select').material_select();

    # Re calculate the total invoice balance if an item is removed
    $(".remove_nested_fields").on "click", ->
      setTimeout (->
        updateInvoiceTotal()
      ), 100

    setDuedate($("#invoice_invoice_date").val(),$("#invoice_payment_terms_id option:selected").attr('number_of_days'))

    # Subtract discount percentage from subtotal
    $("#invoice_discount_percentage, #recurring_profile_discount_percentage").on "blur keyup", ->
      hidePopover($('#invoice_discount_percentage'));
      updateInvoiceTotal()

    $("#invoice_tax_id").on 'change', ->
      updateInvoiceTotal()

    # Subtract discount percentage from subtotal
    $("select#discount_type").change ->
      updateInvoiceTotal()

    # Don't allow paste and right click in discount field
    $("#invoice_discount_percentage, #recurring_profile_discount_percentage, .qty").bind "paste contextmenu", (e) ->
      e.preventDefault()

    # Don't allow nagetive value for discount
    $("#invoice_discount_percentage, #recurring_profile_discount_percentage,.qty").keydown (e) ->
      if e.keyCode is 109 or e.keyCode is 13
        e.preventDefault()
        false

    # re calculate invoice due date on invoice date change
    $("#invoice_invoice_date").change ->
      $(this).qtip("hide") if $(this).qtip()
      term_days = $("#invoice_payment_terms_id option:selected").attr('number_of_days')
      setDuedate($(this).val(),term_days)

    # Calculate line total and invoice total on page load
    $(".invoice_grid_fields tr:visible .line_total").each ->
      updateLineTotal($(this))
      # dont use decimal points in quantity and make cost 2 decimal points
      container = $(this).parents("tr.fields")
      cost = $(container).find("input.cost")
      qty = $(container).find("input.qty")
      cost.val(parseFloat(cost.val()).toFixed(2)) if cost.val()
      qty.val(parseInt(qty.val())) if qty.val()

    updateInvoiceTotal()
    $('.remove_nested_fields').on 'click', ->
      setTimeout (->
        updateInvoiceTotal()
      ), 100
    $('#invoice_grid_fields tbody').sortable
      handle: '.sort_icon'
      items: 'tr.fields'
      axis: 'y'
    $('#invoice_payment_terms_id').unbind 'change'
    $('#invoice_payment_terms_id').change ->
      number_of_days = undefined
      number_of_days = $('option:selected', this).attr('number_of_days')
      setDuedate $('#invoice_invoice_date').val(), number_of_days
    $('#invoice_discount_percentage, #recurring_profile_discount_percentage,.qty').keydown (e) ->
      if e.keyCode == 109 or e.keyCode == 13
        e.preventDefault()
        return false
      return
    $('#invoice_discount_percentage, #recurring_profile_discount_percentage, .qty').bind 'paste contextmenu', (e) ->
      e.preventDefault()


    $("#add_line_item").on "click", ->
      options = $('.items_list:first').html()
      $('.items_list:last').html(options).find('option:selected').removeAttr('selected')
      $('.items_list:last').find('option[data-type = "deleted_item"], option[data-type = "archived_item"], option[data-type = "other_company"], option[data-type = "active_line_item"]').remove()
      tax1 = $('.tax1:first').html()
      tax2 = $('.tax2:first').html()
      $('.tax1:last').html(tax1).find('option:selected').removeAttr('selected')
      $('.tax2:last').html(tax2).find('option:selected').removeAttr('selected')
      $('.tax1:last').find('option[data-type = "deleted_tax"], option[data-type = "archived_tax"], option[data-type = "active_line_item_tax"]').remove()
      $('.tax2:last').find('option[data-type = "deleted_tax"], option[data-type = "archived_tax"], option[data-type = "active_line_item_tax"]').remove()

    $("#invoice_client_id").change ->
      hidePopover($("#invoice_client_id").parents('.select-wrapper'));
    # Change currency of invoice
    $("#invoice_currency_id").unbind 'change'
    $("#invoice_currency_id").change ->
      currency_id = $(this).val()
      hidePopover($("#invoice_currency_id_chzn")) if currency_id is ""
      if not currency_id? or currency_id isnt ""
        $.get('/invoices/selected_currency?currency_id='+ currency_id)

    # Validate client, cost and quantity on invoice save
    $(".invoice-form.form-horizontal").submit ->
      discount_percentage = $("#invoice_discount_percentage").val() || $("#recurring_profile_discount_percentage").val()
      discount_type = $("select#discount_type").val()
      sub_total = $('#invoice_sub_total').val()
      discount_percentage = 0 if not discount_percentage? or discount_percentage is ""
      item_rows = $("table#invoice_grid_fields tr.fields:visible")
      flag = true
      # Check if company is selected
      if $("#invoice_company_id").val() is ""
        applyPopover($("#invoice_company_id_chzn"),"bottomMiddle","topLeft","Select a company")
        flag = false
        # Check if client is selected
      else if $("#invoice_client_id").val() is ""
        applyPopover($("#invoice_client_id").parents('.select-wrapper'),"bottomMiddle","topLeft","Select a client")
        flag = false
        # if currency is not selected
      else if $("#invoice_currency_id").val() is "" and $("#invoice_currency_id").is( ":hidden" ) == false
        applyPopover($("#invoice_currency_id_chzn"),"bottomMiddle","topLeft","Select currency")
        flag = false
        # check if invoice date is selected
      else if $("#invoice_invoice_date").val() is ""
        applyPopover($("#invoice_invoice_date"),"rightTop","leftMiddle","Select invoice date")
        flag =false
      else if $("#invoice_invoice_date").val() isnt "" and !DateFormats.validate_date($("#invoice_invoice_date").val())
        applyPopover($("#invoice_invoice_date"),"rightTop","leftMiddle","Make sure date format is in '#{DateFormats.format()}' format")
        flag = false
      else if $("#invoice_due_date").val() isnt "" and !DateFormats.validate_date($("#invoice_due_date").val())
        applyPopover($("#invoice_due_date"),"rightTop","leftMiddle","Make sure date format is in '#{DateFormats.format()}' format")
        flag = false
        # Check if payment term is selected
      else if $("#invoice_payment_terms_id").val() is ""
        applyPopover($("#invoice_payment_terms_id_chzn"),"bottomMiddle","topLeft","Select a payment term")
        flag = false
        # Check if discount percentage is an integer
      else if $("input#invoice_discount_percentage").val()  isnt "" and ($("input#invoice_discount_percentage").val() < 0)
        applyPopover($("#invoice_discount_percentage"),"bottomMiddle","topLeft","Enter Valid Discount")
        flag = false
        # Check if no item is selected
      else if $("tr.fields:visible").length < 1
        applyPopover($("#add_line_item"),"bottomMiddle","topLeft","Add line item")
        flag = false
        # Check if item is selected
      else if item_rows.find("select.items_list option:selected[value='']").length is item_rows.length
        first_item = $("table#invoice_grid_fields tr.fields:visible:first")
        applyPopover(first_item,"bottomMiddle","topLeft","Select an item")
        flag = false
      else if discount_type == '%' and parseFloat(discount_percentage) > 100.00
        applyPopover($("#invoice_discount_percentage"),"bottomMiddle","topLeft","Percentage must be hundred or less")
        flag = false
      else if discount_type != '%' and parseFloat(discount_percentage) > parseFloat(sub_total)
        applyPopover($("#invoice_discount_percentage"),"bottomMiddle","topLeft","Discount must be less than sub-total")
        flag = false

        # Item cost and quantity should be greater then 0
      else
        $("tr.fields:visible").each ->
          row = $(this)
          if row.find("select.items_list").val() isnt ""
            cost = row.find(".cost")
            qty =  row.find(".qty")
            tax1 = row.find("select.tax1")
            tax2 = row.find("select.tax2")
            tax1_value = $("option:selected",tax1).val()
            tax2_value = $("option:selected",tax2).val()

            if not $.isNumeric(cost.val()) and cost.val() isnt ""
              applyPopover(cost,"bottomLeft","topLeft","Enter valid Item cost")
              flag = false
            else hidePopover(cost)

            if not $.isNumeric(qty.val())  and qty.val() isnt ""
              applyPopover(qty,"bottomLeft","topLeft","Enter valid Item quantity")
              flag = false
            else hidePopover(qty)
      flag