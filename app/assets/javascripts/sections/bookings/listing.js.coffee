# Each Listing has it's own object which keeps track of number booked, availability etc.
class @Bookings.Listing

  defaultQuantity: 1

  constructor: (@data) ->
    @id = parseInt(@data.id, 10)
    @firstAvailableDate = DNM.util.Date.idToDate(@data.first_available_date)

    if @isReservedHourly()
      @availability = new HourlyAvailability(
        @data.availability,
        @data.hourly_availability_schedule,
        @data.hourly_availability_schedule_url
      )
    else
      @availability = new Availability(@data.availability)

    @bookedDatesArray = []

    @minimumBookingDays = @data.minimum_booking_days
    @minimumDate = DNM.util.Date.idToDate(@data.minimum_date)
    @maximumDate = DNM.util.Date.idToDate(@data.maximum_date)
    @favourablePricingRate = @data.favourable_pricing_rate
    @pricesByDays = @data.prices_by_days
    @hourlyPrice = @data.hourly_price_cents
    @recurringBooking = @data.recurring_booking

  setDefaultQuantity: (qty) ->
    @defaultQuantity = qty if qty >= 0

  getQuantity: ->
    @defaultQuantity

  hasFavourablePricingRate: ->
    @favourablePricingRate

  isReservedHourly: ->
    @data.hourly_reservations

  isRecurringBooking: ->
    @recurringBooking

  isReservedDaily: ->
    !@isReservedHourly()

  # Returns whether the date is within the bounds available for booking
  dateWithinBounds: (date) ->
    time = date.getTime()
    return false if time < @minimumDate.getTime()
    return false if time > @maximumDate.getTime()
    true

  canBookDate: (date, min) ->
    @availabilityFor(date, min) >= @defaultQuantity

  availabilityFor: (date, minute = null) ->
    @availability.availableFor(date, minute)

  openFor: (date) ->
    @availability.openFor(date)

  isBooked: ->
    hasDate = if @isRecurringBooking()
      @startOn and @endOn
    else
      @bookedDates().length > 0
    hasTime = if @isReservedHourly()
      @minutesBooked() > 0
    else
      true
    hasDate and hasTime

  # Return the days where there exist bookings
  bookedDays: ->
    (DNM.util.Date.toId(date) for date in @bookedDates())

  # Return the days where bookings exist as Date objects
  bookedDates: ->
    @bookedDatesArray

  # Return the subtotal for booking this listing
  bookingSubtotal: ->
    @priceCalculator().getPrice()

  priceCalculator: ->
    if @isReservedHourly()
      new Bookings.PriceCalculator.HourlyPriceCalculator(this)
    else
      new Bookings.PriceCalculator(this)

  # Set the dates active on this listing for booking
  setDates: (dates) ->
    @bookedDatesArray = dates

  # Set the start/end minutes for an hourly listing reservation.
  setTimes: (start, end) ->
    @startMinute = start
    @endMinute = end

  setStartOn: (start) ->
    @startOn = start

  setEndOn: (end) ->
    @endOn = end

  minutesBooked: ->
    return 0 unless @startMinute? and @endMinute?
    @endMinute - @startMinute

  # Check the selected dates are valid with the quantity
  # and availability
  bookingValid: ->
    for date in @bookedDates()
      if @availabilityFor(date) < @getQuantity()
        return false
    true

  reservationOptions: ->
    options = {
      dates: @bookedDays(),
      quantity: @getQuantity()
    }

    # Hourly reserved listings send through the start/end minute of
    # the day with the booking request.
    if @isReservedHourly()
      options.start_minute = @startMinute
      options.end_minute   = @endMinute
    if @isRecurringBooking()
      options.start_on = @startOn
      options.end_on   = @endOn

    options

  # Wrap queries on the availability data
  class Availability
    constructor: (@data) ->

    openFor: (date) ->
      @_value(date) != null

    availableFor: (date) ->
      @_value(date) or 0

    _value: (date) ->
      if month = @data["#{date.getFullYear()}-#{date.getMonth()+1}"]
        month[date.getDate()-1]
      else
        null

  # Extends the simple daily availability wrapper to provide quantity
  # down to the hourly level for specific days. Provides the same semantics
  # if called without a provided minute, or provides hourly semantics if called
  # with a minute as an additional parameter.
  # Encapsulates deferred loading of the hourly availability.
  class HourlyAvailability extends Availability
    constructor: (@data, @schedule, @scheduleUrl) ->
      super(@data)

    openFor: (date, minute) ->
      @_value(date, minute) != null

    availableFor: (date, minute) ->
      @_value(date, minute) or 0

    hasSchedule: (date) ->
      !!@_schedule(date)

    # Fire off a remote request (if required) to load the hourly availability
    # schedule for a given date. Execute the provided callback when ready
    # to use.
    loadSchedule: (date, callback) ->
      if !@hasSchedule(date)
        dateId = DNM.util.Date.toId(date)
        $.get(@scheduleUrl + "?date=#{dateId}").success (data) =>
          @schedule[dateId] = data
          callback(date)
      else
        callback(date)

    _schedule: (date) ->
      @schedule[DNM.util.Date.toId(date)]

    _value: (date, minute) ->
      if minute
        if hours = @_schedule(date)
          hours[minute.toString()] or null
        else
          super(date)
      else
        super(date)

