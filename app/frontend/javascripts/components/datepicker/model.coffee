asEvented = require('asevented')
dateUtil = require('../../lib/utils/date')

# Internal backing model for datepicker data
module.exports = class DatepickerModel
  asEvented.call @prototype

  defaultOptions: {
    # The initial month of the view, specified as a Date object
    currentMonth: null,

    # The 'today' for the view, specified as a Date object
    today: new Date(),

    # The initial 'selected dates' for the calendar
    selectedDates: [],

    # Can dates be changed?
    immutable: false
  }

  constructor: (@options) ->
    @options = $.extend({}, @defaultOptions, @options)
    @currentMonth = @options.currentMonth
    @immutable = @options.immutable
    @_included = []
    @today = @options.today

    @setDates(@options.selectedDates) if @options.selectedDates

  advanceMonth: (incr = 1) ->
    @currentMonth = new Date(@currentMonth.getFullYear(), @currentMonth.getMonth()+incr, 1, 0, 0, 0, 0)
    @trigger('monthChanged', @currentMonth)

  setCurrentMonth: (newMonth) ->
    @currentMonth = new Date(newMonth.getFullYear(), newMonth.getMonth(), 1, 0, 0, 0, 0)
    @trigger('monthChanged', @currentMonth)

  getCurrentMonth: ->
    @currentMonth ||= _.last(@getDates()) or new Date()

  isSelected: (date) ->
    _.contains(@_included, @_asId(date))

  getDates: ->
    dates = _.map @_included, (dateId) => @_fromId(dateId)
    _.sortBy(dates, (date) -> date.getTime())

  toggleDate: (date) ->
    return if @immutable
    if @isSelected(date)
      @removeDate(date)
    else
      @addDate(date)

  removeDate: (date) ->
    @trigger('dateRemoved', date) if @_removeDate(date)

  addDate: (date) ->
    @trigger('dateAdded', date) if @_addDate(date)

  setDates: (dates) ->
    newDates = []
    newDates.push(@_asId(date)) for date in dates

    added = _.difference(newDates, @_included)
    removed = _.difference(@_included, newDates)

    @removeDate(@_fromId(date)) for date in removed
    @addDate(@_fromId(date)) for date in added

  clear: ->
    @setDates([])

  _addDate: (date) ->
    dateId = @_asId(date)
    return if @isSelected(dateId)

    @_included.push dateId
    true

  _removeDate: (date) ->
    dateId = @_asId(date)
    return unless @isSelected(dateId)
    @_included.splice _.indexOf(@_included, dateId), 1
    true

  _asId: (date) ->
    dateUtil.toId(date)

  _fromId: (dateId) ->
    dateUtil.idToDate(dateId)
