class @AvailabilityRulesController

  constructor: (@container) ->
    if @container.find('input[type=radio][name*=availability_template]').length > 0
      @selector = @container.find('input[type=radio][name*=availability_template]')
      @customFields = @container.find('.custom-availability-rules')
      @clearField = @container.find('[name*=defer_availability_rules]')

      # Set up event listeners
      @bindEvents()

      # Set up defaults
      @setupDefaults()

      # Update for initial state
      @updateCustomState()
      @updateDayStates()
      if @selector.filter(':checked').attr('data-custom-rules')?
        $( document ).ready ->
          $('select').trigger('render')

  setupDefaults: ->
    @container.find('.close-time select').each ->
      if $(this).val() == '0:00'
        $(this).val('23:45')

  updateCustomState: ->
    if @selector.filter(':checked').attr('data-custom-rules')?
      @showCustom()
    else
      @hideCustom()

    if @selector.filter(':checked').attr('data-clear-rules')?
      @clearField.prop('checked', true)
    else
      @clearField.prop('checked', false)
    @container.find('select').trigger('render')

  updateDayStates: ->
    @customFields.find('input[name*=destroy]').each (i, element) =>
      @updateClosedState($(element))
    @container.find('select').trigger('render')

  showCustom: ->
    @customFields.find('input, select').prop('disabled', false)
    @customFields.find('.disabled').removeClass('disabled')
    @customFields.show()
    @updateDayStates()

  hideCustom: ->
    @customFields.hide()
    @customFields.find('input, select').prop('disabled', true)

  updateClosedState: (checkbox) ->
    return unless @customFields.is(':visible')

    times = checkbox.closest('.day').find('.open-time select, .close-time select')
    if checkbox.is(':checked')
      times.prop('disabled', true)
    else
      times.prop('disabled', false)

  bindEvents: ->
    # Whenever the template selector changes we need to update the state of the UI
    @selector.change (event) =>
      @updateCustomState()

    # Whenever changing open state we need to hide/show the time fields
    @customFields.on 'change', 'input.open-checkbox', (event) =>
      checkbox = $(event.target)
      day = checkbox.closest('.day')
      destroy_checkbox = day.find('input[name*=destroy]').prop('checked', !checkbox.is(':checked'))
      @updateClosedState(destroy_checkbox)

