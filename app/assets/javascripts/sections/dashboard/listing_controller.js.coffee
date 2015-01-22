class @Dashboard.ListingController

  constructor: (@container) ->
    @availabilityRules = new AvailabilityRulesController(@container)

    @currencySelect = @container.find('#currency-select')
    @locationRadios = @container.find('#location-list input[type="radio"]')
    @currencyHolders = @container.find('.currency-holder')
    @currencyLocationHolders = @container.find('.currency_addon')

    @enableSwitch = @container.find('#listing_enabled').parent().parent()
    @enableAjaxUpdate = true

    @initializePriceFields()
    @bindEvents()
    @updateCurrency()
    if ( @locationRadios.length > 0 )
      @updateCurrencyFromLocation()

  bindEvents: =>

    @container.on 'change', @currencySelect, (event) =>
      @updateCurrency()

    if ( @locationRadios.length > 0 )
      @locationRadios.on 'change', =>
        @updateCurrencyFromLocation()


    @enableSwitch.on 'switch-change', (e, data) =>
      enabled_should_be_changed_by_ajax = @enableSwitch.data('ajax-updateable')
      if enabled_should_be_changed_by_ajax?
        value = data.value
        if @enableAjaxUpdate
          url = @container.attr("action")
          if value
            url += '/enable'
          else
            url += '/disable'
          $.ajax
            url: url
            type: 'GET'
            dataType: 'JSON'
            error: (jq, textStatus, err) =>
              @enableAjaxUpdate = false
              @enableSwitch.find('#listing_enabled').siblings('label').trigger('mousedown').trigger('mouseup').trigger('click')
        else
          @enableAjaxUpdate = true


  updateCurrency: () =>
    @currencyHolders.html($('#currency_'+ @currencySelect.val()).text())

  updateCurrencyFromLocation: ->
    @currencyLocationHolders.html(@container.find('#location-list input[type="radio"]:checked').next().val())

  initializePriceFields: ->
    @priceFieldsFree = new PriceFields(@container.find('.price-inputs-free'))
    @priceFieldsHourly = new PriceFields(@container.find('.price-inputs-hourly'))
    @priceFieldsDaily = new PriceFields(@container.find('.price-inputs-daily'))


    @freeInput = @container.find('.price-inputs-free').find('input[type="radio"]')
    @dailyInput = @container.find('.price-inputs-daily').find('input[type="radio"]')
    @hourlyInput = @container.find('.price-inputs-hourly').find('input[type="radio"]')

    @hideNotCheckedPriceFields()

    @freeInput.on 'change', (e) =>
      @togglePriceFields()

    @hourlyInput.on 'change', (e) =>
      @togglePriceFields()

    @dailyInput.on 'change', (e) =>
      @togglePriceFields()

  togglePriceFields: ->
    if @freeInput.is(':checked')
      @priceFieldsFree.show()
      @priceFieldsHourly.hide()
      @priceFieldsDaily.hide()
    else if @hourlyInput.is(':checked')
      @priceFieldsFree.hide()
      @priceFieldsHourly.show()
      @priceFieldsDaily.hide()
    else if @dailyInput.is(':checked')
      @priceFieldsFree.hide()
      @priceFieldsHourly.hide()
      @priceFieldsDaily.show()

  hideNotCheckedPriceFields: ->
    @priceFieldsFree.hide() unless @freeInput.is(':checked')
    @priceFieldsHourly.hide() unless @hourlyInput.is(':checked')
    @priceFieldsDaily.hide() unless @dailyInput.is(':checked')


