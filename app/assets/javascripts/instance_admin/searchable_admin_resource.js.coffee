@SearchableAdminResource =

  commonBindEvents: ->
    @container.find('#to, #from').datepicker()

    @container.on 'click', '#to, #from', (e) =>
      e.stopPropagation()

    @container.find('.date-dropdown').on 'click', 'li:not(.date-range)', ->
      $('.date-dropdown').find('li.selected').removeClass('selected')
      $(@).addClass('selected')
      dateValue = $(@).find('a').data('date')
      selected = $(@).find('a').text()
      $('.dropdown-trigger .current').text(selected)
      $('.dropdown-trigger input[type="hidden"]').attr('value', dateValue)
      $(@).parents('form').submit()

    @container.find('.date-dropdown').on 'click', '.apply-filter', ->
      startDate = $('#from').val()
      endDate = $('#to').val()
      if startDate && endDate
        $('input[type="hidden"]#date').val(startDate + '-' + endDate)
        $(@).parents('form').submit()

