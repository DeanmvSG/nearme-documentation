Modal = require('../../components/modal')
Dialog = require('../../new_ui/modules/dialog')

module.exports = class OverlappingReservationsController
  constructor: (@container, @review_options = {}) ->
    @dateField = @container.find('#order_dates')
    @visibleDateField = @container.find('.jquery-datepicker')
    @validatorUrl = @container.data('validator-url')

  formAttributes: ->
    {
      date: @dateField.val()
    }

  checkNewDate: ->
    @clearWarnings()
    $.getJSON(@validatorUrl, @formAttributes()).then @handleResponse

  handleResponse: (response) =>
    return unless response.warnings
    warning = $('<div class="warning"></div>').html(response.warnings.overlaping_reservations)

    @displayMessage(warning)

  clearWarnings: () ->
    @visibleDateField.siblings('.warning').remove()

  displayMessage: (warning) ->
    @visibleDateField.parent().append(warning)
