class @Task

  @load_functions = ->

    $('.modal').modal complete: ->
      $('.qtip').remove()

    # Task form validation
    $(".task_form").submit ->
      name = $("#task_name").val()
      rate = $("#task_rate").val()
      association_name = $('input[name=association]:checked').attr("id")
      no_of_selected_companies = $('.company_checkbox:checked').length

      flag = false
      if name is ""
        applyPopover($("#task_name"),"bottomMiddle","topLeft","Enter a name for the task")
        flag = false
      else if rate is ""
        applyPopover($("#task_rate"),"bottomMiddle","topLeft","Enter rate per hour for the task")
        flag = false
        hidePopover($("#task_name"))
      else if rate < 0
        applyPopover($("#task_rate"),"bottomMiddle","topLeft","Enter postive value of rate per hour for the task")
        flag = false
        hidePopover($("#task_name"))
      else if association_name == undefined
        hidePopover($("#task_rate"))
        applyPopover($("input[name=association]"),"topright","leftcenter","Select aleast one company for the task")
      else if (association_name == "company_association" and no_of_selected_companies == 0)
        hidePopover($("#task_rate"))
        applyPopover($("input[name=association]:checked"),"topright","leftcenter","Select aleast one company for the task")
        flag = false
      else
        flag = true
        hidePopover($("input[name=association]:checked"))
      flag

    jQuery('#account_association').change ->
      if jQuery(this).is ':checked'
        $('.company_checkbox').prop('checked',true)

    $('#task_name').on "change", ->
      return hidePopover($("#task_name"))

    $('.company_checkbox').on "change", ->
      return hidePopover($("#company_association"))

  applyPopover = (elem,position,corner,message) ->
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


  hidePopover = (elem) ->
    elem.qtip("hide")
