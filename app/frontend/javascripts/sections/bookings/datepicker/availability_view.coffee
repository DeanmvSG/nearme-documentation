DatepickerView = require('../../../components/datepicker/view')

# A view wrapper for the Datepicker to show a loading indicator while we load the date availability

module.exports = class AvailabilityView extends DatepickerView
  constructor: (@listing, options = {}) ->
    super(options)

  show: ->
    # Refresh if listing quantity has changed since last display
    # We do this to update the display of available vs unavailable dates
    if @lastDefaultQuantity && @listing.defaultQuantity != @lastDefaultQuantity
      @refresh()

    @lastDefaultQuantity = @listing.defaultQuantity
    super

  # Extend the class generation method to add disabled state if the listing quantity selection
  # exceeds the availability for a given date.
  classForDate: (date, monthDate) ->
    klass = [super]
    qty = @listing.defaultQuantity
    qty = 1 if qty < 1

    klass.push 'disabled' unless @listing.availabilityFor(date) >= qty
    klass.push 'closed' unless @listing.openFor(date)

    # Our custom model keeps track of whether dates were added via the range
    # selection.
    if @model.isRangeDate and @model.isRangeDate(date)
      klass.push 'implicit'

    klass.join ' '
