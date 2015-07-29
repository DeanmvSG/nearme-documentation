# Base search controller
# Extended by Search.HomeController and Search.SearchController
class Search.Controller
  constructor: (@form) ->
    @initializeFields()
    @initializeGeolocateButton()
    @initializeSearchButton()
    if @autocompleteEnabled()
      @initializeAutocomplete()
    @initializeGeocoder()

  initializeAutocomplete: ->
    @autocomplete = new google.maps.places.Autocomplete(@queryField[0], {})
    @submit_form = false
    google.maps.event.addListener @autocomplete, 'place_changed', =>
      place = Search.Geocoder.wrapResult @autocomplete.getPlace()
      place = null unless place.isValid()

      @setGeolocatedQuery(@queryField.val(), place)
      @fieldChanged('query', @queryField.val())
      if @submit_form
        @form.submit()

  initializeGeocoder: ->
    @geocoder = new Search.Geocoder()

  # Initialize all filters for the search form
  initializeFields: ->
    @priceRange = new PriceRange(@form.find('.price-range'), 300, @)
    @initializeQueryField()

  fieldChanged: (filter, value) ->
    # Override to trigger automatic updating etc.

  initializeQueryField: ->
    @queryField = @form.find('input#search')
    @keywordField = @form.find('input[name="query"]')

    query_value = DNM.util.Url.getParameterByName('loc')


    @queryField.bind 'change', =>
      @fieldChanged('query', @queryField.val())

    @queryField.bind 'focus', =>
      if @queryField.val() is @queryField.data('placeholder')
        @queryField.val('')
      true

    @queryField.bind 'blur', =>
      if @queryField.val().length < 1 and @queryField.data('placeholder')?
        _.defer(=>@queryField.val(@queryField.data('placeholder')))
      true

    # TODO: Trigger fieldChanged on keypress after a few seconds timeout?

  initializeGeolocateButton: ->
    @geolocateButton = @form.find(".geolocation")
    @geolocateButton.addClass("active").bind 'click', =>
      @geolocateMe()

  initializeSearchButton: ->
    @searchButton = @form.find(".search-icon")
    if @searchButton.length > 0
      @searchButton.bind 'click', =>
        @form.submit()

  geolocateMe: ->
    @determineUserLocation()

  determineUserLocation: ->
    return unless Modernizr.geolocation
    navigator.geolocation.getCurrentPosition (position) =>
      deferred = @geocoder.reverseGeocodeLatLng(position.coords.latitude, position.coords.longitude)
      deferred.done (resultset) =>
        cityAndStateAddress = resultset.getBestResult().cityAndStateAddress()

        existingVal = @queryField.val()
        if cityAndStateAddress != existingVal
          # two cached variables are used in Search.HomeController in form.submit handler
          @cached_geolocate_me_result_set = resultset.getBestResult()
          @cached_geolocate_me_city_address = cityAndStateAddress
          @queryField.val(cityAndStateAddress).data('placeholder', cityAndStateAddress)
          @fieldChanged('query', @queryField.val())
          @setGeolocatedQuery(@queryField.val(), @cached_geolocate_me_result_set)
          @storeUserLocation(position)

  storeUserLocation: (position) ->
    $.post('/users/store_geolocated_location', { longitude: position.coords.longitude, latitude: position.coords.latitude })

  # Is the given query currently geolocated by the search
  isQueryGeolocated: (query) ->
    # Note that we don't check the presence of the gelocation result. This is because the result can be null,
    # which means geolocation was attempted but failed, so we don't try again.
    @currentGeolocationResultQuery == query

  # Set the active geolocated query. Triggers updating of the form params.
  setGeolocatedQuery: (query, result) ->
    @currentGeolocationResultQuery = query
    @currentGeolocationResult = result
    @assignFormParams @searchParamsFromGeolocationResult(result)

  # Returns special search params based on a geolocation result (Search.Geolocator.Result), or no result.
  searchParamsFromGeolocationResult: (result) ->
    params = { lat: null, lng: null, nx: null, ny: null, sx: null, sy: null, \
               country: null, state: null, city: null, suburb: null, street: null,
               postcode: null
    }

    if result
      boundingBox = result.boundingBox()
      params['lat'] = @formatCoordinate(result.lat())
      params['lng'] = @formatCoordinate(result.lng())
      params['nx']  = @formatCoordinate(boundingBox[0])
      params['ny']  = @formatCoordinate(boundingBox[1])
      params['sx']  = @formatCoordinate(boundingBox[2])
      params['sy']  = @formatCoordinate(boundingBox[3])
      params['country'] = result.country()
      params['state']   = result.state()
      params['city']    = result.city()
      params['suburb']  = result.suburb()
      params['street']  = result.street()
      params['postcode']  = result.postcode()
    params['loc'] = @buildSeoFriendlyQuery(result)
    params['query'] = @keywordField.val()

    params


  buildSeoFriendlyQuery: (result) ->
    query = $.trim(@form.find("input#search").val().replace(', United States', ''))

    if result
      if result.country() and result.country() == 'United States'
        stateRegexp = new RegExp("#{result.state()}$", 'i')
        if result.state() and query.match(stateRegexp)
          query = query.replace(stateRegexp, result.stateShort())

      query
    else
      query


  formatCoordinate: (coord) ->
    coord.toFixed(5) if coord?

  assignFormParams: (paramsHash) ->
    # Write params to search form
    for field, value of paramsHash
      if field == 'lg_custom_attributes'
        for key, val of value
          @form.parent().find('input[name="lg_custom_attributes[' + key + ']"]').val(val)
      else
        @form.parent().find("input[name='#{field}']").val(value)

  getSearchParams: ->
    form_params = @form.serializeArray()
    form_params = @replaceWithData(form_params)
    # don't polute url if this is unnecessary - ignore empty values and page
    params = []
    for k, param of form_params
      if param["name"] != 'page' && param["value"] != ''
        params.push(param)
    params

  # Geocde the search query and assign it as the geocoded result
  geocodeSearchQuery: (callback) ->
    query = @queryField.val()

    # If the query has already been geolocated we can just search immediately
    if @isQueryGeolocated(query)
      return callback()
    # Otherwise we need to geolocate the query and assign it before searching
    deferred = @geocoder.geocodeAddress(query)
    deferred.always (results) =>
      result = results.getBestResult() if results

      @setGeolocatedQuery(query, result)
      callback()

  # If element has data-value attribute it will replace native value of the element
  # Used for date range picker
  replaceWithData: (formParams)->
    params = []
    for k, param of formParams
      element = @form.find("input[name='#{param['name']}']")
      if element.data('value')
        params.push {name: param['name'], value: element.data('value')}
      else
        params.push(param)
    params

  autocompleteEnabled: ->
    @queryField.data('disable-autocomplete') == undefined

  responsiveCategoryTree: ->
    if $("#category-tree").length > 0
      $(window).resize =>
        @categoryTreeInit(true)
      @categoryTreeInit(false)

  categoryTreeInit: (windowResized)->
    if ($(window).width() < 767)
      $("#category-tree .categories-list:first").hide()
      $(".nav-heading input:checked").parents('.nav-heading').next().show()
      $(".nav-heading input").on 'change', (event) ->
        $(".nav-heading input:not(:checked)").parents('.nav-heading').next().hide('slow')
        $(".nav-heading input:not(:checked)").parents('.nav-heading').next().find('input:checkbox').prop('checked', false);
        $(".nav-heading input:checked").parents('.nav-heading').next().show('slow')
    else
      $(".nav-heading input").parents('.nav-heading').next().show()
      $(".nav-heading input").unbind 'change'

    unless windowResized
      $('.nav-categories  > ul > .categories-list > .nav-item ').find('.categories-list').hide()

    $(".nav-item input[type='checkbox']").on 'change', (event) ->
      if $(event.target).prop('checked')
        $(event.target).parent().next().show()
      else
        $(event.target).parent().parent().find('.categories-list').hide()
        $(event.target).parent().next().find('input:checked').prop('checked', false)

