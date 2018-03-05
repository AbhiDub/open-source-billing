# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('.report-section  #from_date_icon, .report-section #from_date').pickadate
    format: "yyyy-mm-dd"
    formatSubmit: DateFormats.format()
    onSet: (context) ->
      value = @get('value')
      $('.report-section #from_date').val value

  $('.report-section  #to_date_icon, .report-section  #to_date').pickadate
    format: "yyyy-mm-dd"
    formatSubmit: DateFormats.format()
    onSet: (context) ->
      value = @get('value')
      $('.report-section  #to_date').val value

