# Controller for Search results and filtering page
#
# FIXME: This and the home search form should be separate. Instead we should abstract out
#        a common "search query" input field which handles the geolocation of the query,
#        and notifies observers when it is changed.
class Search.SearchController extends Search.Controller
  constructor: (form, @container) ->
    super(form)
    @redirectIfNecessary()
    @initializeDateRangeField()

    @listings = {}
    @resultsContainer = => @container.find('#results')
    @loader = new Search.ScreenLockLoader => @container.find('.loading')
    @resultsCountContainer = $('#search_results_count')
    @filters = $('a[data-search-filter]')
    @filters_container = $('div[data-search-filters-container]')
    @processingResults = true
    @initializeMap()
    @bindEvents()
    @initializeEndlessScrolling()
    @reinitializeEndlessScrolling = false
    @updateFiltersBasedOnListingsIds()
    setTimeout((=> @processingResults = false), 1000)

  bindEvents: ->


    @form.bind 'submit', (event) =>
      event.preventDefault()
      @triggerSearchFromQuery()
    
    @closeFilterIfClickedOutside()

    @filters.on 'click', (event) ->
      # allow to hide already opened element
      if $(this).parent().find('ul').is(':visible')
        _this.hideFilters()
      else
        _this.hideFilters()
        $(this).parent().find('ul').toggle()
        $(this).parent().toggleClass('active')
      false

    @filters_container.on 'click', 'input[type=checkbox]', =>
      @fieldChanged()

    @searchField = @form.find('#search')
    @searchField.on 'focus', => $(@form).addClass('query-active')
    @searchField.on 'blur', => $(@form).removeClass('query-active')
    
    if @map?
      @map.on 'click', =>
        @searchField.blur()
      
      @map.on 'viewportChanged', =>
        # NB: The viewport can change during 'query based' result loading, when the map fits
        #     the bounds of the search results. We don't want to trigger a bounding box based
        #     lookup during a controlled viewport change such as this.
        return if @processingResults
        return unless @redoSearchMapControl.isEnabled()
      
        @triggerSearchWithBoundsAfterDelay()

  hideFilters: ->
    for filter in @filters
      $(filter).parent().find('ul').hide()
      $(filter).parent().removeClass('active')

  closeFilterIfClickedOutside: ->
    $('body').on 'click', (event) =>
      if $(@filters_container).has(event.target).length == 0
        @hideFilters()
  # for browsers without native html 5 support for history [ mainly IE lte 9 ] the url looks like:
  # /search?q=OLDQUERY#search?q=NEWQUERY. Initially, results are loaded for OLDQUERY.
  # This methods checks, if OLDQUERY == NEWQUERY, and if not, it redirect to the url after # 
  # [ which is stored in History.getState() and contains NEWQUERY ].
  # Updating the form instead of redirecting could be a little bit better, 
  # but there are issues with updating google maps view etc. - remember to check it if you update the code
  redirectIfNecessary: ->
    if History.getState() && !window.history?.replaceState
      for k, param of History.getState().data
        if param.name == 'q'
          if param.value != DNM.util.Url.getParameterByName('q')
            document.location = History.getState().url

  
  initializeDateRangeField: ->
    @rangeDatePicker = new Search.RangeDatePickerFilter(
      @form.find('.availability-date-start'),
      @form.find('.availability-date-end'),
      (dates) => @fieldChanged('dateRange', dates)
    )

  initializeEndlessScrolling: ->
    $('#results').scrollTop(0)
    jQuery.ias({
      container : '#results',
      item: '.listing',
      pagination: '.pagination',
      next: '.next_page',
      triggerPageThreshold: 99,
      history: false,
      thresholdMargin: -90,
      loader: '<div class="row-fluid span12"><h1><img src="' + $('img[alt=Spinner]').eq(0).attr('src') + '"><span>Loading More Results</span></h1></div>',
      onRenderComplete: (items) ->
        for item in items
          Search.SearchResultController.handleResult($(item))

        # when there are no more resuls, add special div element which tells us, that we need to reinitialize ias - it disables itself on the last page...
        if !$('#results .pagination .next_page').attr('href')
          $('#results').append('<div id="reinitialize"></div>')
          reinitialize = $('#reinitialize')
    })

  initializeMap: ->
    mapContainer = @container.find('#listings_map')[0]
    return unless mapContainer
    @map = new Search.Map(mapContainer, this)

    # Add our map viewport search control, which enables/disables searching on map move
    @redoSearchMapControl = new Search.RedoSearchMapControl(enabled: true)
    @map.addControl(@redoSearchMapControl)
    
    resizeMapThrottle = _.throttle((=> @map.resizeToFillViewport()), 200)
    
    $(window).resize resizeMapThrottle
    $(window).trigger('resize')
    
    @updateMapWithListingResults()

  showResults: (html) ->
    @resultsContainer().replaceWith(html)
    $('.pagination').hide()

  updateResultsCount: ->
    count = @resultsContainer().find('.listing:not(.hidden)').length
    inflection = 'result'
    inflection += 's' unless count == 1
    @resultsCountContainer.html("#{count} #{inflection}")
  
  # Update the map with the current listing results, and adjust the map display.
  updateMapWithListingResults: ->
    @map.popover.close()
    
    listings = @getListingsFromResults()
    
    if listings? and listings.length > 0
      @map.plotListings(listings)
      
      # Only show bounds of new results
      bounds = new google.maps.LatLngBounds()
      bounds.extend(listing.latLng()) for listing in listings
      _.defer => @map.fitBounds(bounds)
      
      @map.show()
      
      # In case the map is hidden
      @map.resizeToFillViewport()
      
    else
      @map.hide()

  # Within the current map display, plot the listings from the current results. Remove listings
  # that aren't within the current map bounds from the results.
  plotListingResultsWithinBounds: ->
    for listing in @getListingsFromResults()
      wasPlotted = @map.plotListingIfInMapBounds(listing)
      listing.hide() unless wasPlotted

    @updateResultsCount()

  # Return Search.Listing objects from the search results.
  getListingsFromResults: ->
    listings = []
    @resultsContainer().find('.listing').each (i, el) =>
      listing = @listingForElementOrBuild(el)
      listings.push listing
    listings

  # Initialize or build a Search.Listing object from the DOM element.
  # Handles memoizing by listing ID and swapping the backing DOM element
  # for the leasting from search result refreshes/changes.
  #
  # TODO: Migrate to generating the result HTML elements client-side so we can
  #       avoid this complexity.
  listingForElementOrBuild: (element) ->
    id = $(element).attr('data-id')
    listing = @listings[id] ?= Search.Listing.forElement(element)
    listing.setElement(element)
    listing

  # Triggers a search request with the current map bounds as the geo constraint
  triggerSearchWithBounds: ->
    bounds = @map.getBoundsArray()
    @assignFormParams(
      nx: @formatCoordinate(bounds[0]),
      ny: @formatCoordinate(bounds[1]),
      sx: @formatCoordinate(bounds[2]),
      sy: @formatCoordinate(bounds[3]),
      ignore_search_event: 1
    )

    @triggerSearchAndHandleResults =>
      @plotListingResultsWithinBounds()
      @assignFormParams(
        ignore_search_event: 1
      )

  # Provide a debounced method to trigger the search after a period of constant state
  triggerSearchWithBoundsAfterDelay: _.debounce(->
    @triggerSearchWithBounds()
  , 300)

  # Trigger the search from manipulating the query.
  # Note that the behaviour semantics are different to manually moving the map.
  triggerSearchFromQuery: ->
    # we want to log any new search query
    @assignFormParams(
      ignore_search_event: 0
    )
    @loader.showWithoutLocker()
     # Infinite-Ajax-Scroller [ ias ] which we use disables itself when there are no more results
     # we need to reenable it when it is necessary, and only then - otherwise we will get duplicates
    if $('#reinitialize').length > 0
      @initializeEndlessScrolling()
    @geocodeSearchQuery =>
      @triggerSearchAndHandleResults =>
        @updateFiltersBasedOnListingsIds()
        @updateMapWithListingResults() if @map?

  # Trigger the search after waiting a set time for further updated user input/filters
  triggerSearchFromQueryAfterDelay: _.debounce(->
    @triggerSearchFromQuery()
  , 2000)

  # Triggers a search with default UX behaviour and semantics.
  triggerSearchAndHandleResults: (callback) ->
    @loader.showWithoutLocker()
    @triggerSearchRequest().success (html) =>
      @processingResults = true
      @updateUrlForSearchQuery()
      @updateLinksForSearchQuery()
      @showResults(html)
      window.scrollTo(0, 0) if !@map
      @loader.hide()

      callback() if callback
      _.defer => @processingResults = false

  # Trigger the API request for search
  #
  # Returns a jQuery Promise object which can be bound to execute response semantics.
  triggerSearchRequest: ->
    $.ajax(
      url  : @form.attr("action")
      type : 'GET',
      data : @form.serialize()
    )

  updateListings: (listings, callback, error_callback = ->) ->
    @triggerListingsRequest(listings).success (html) =>
      html = "<div>" + html + "</div>"
      listing.setHtml($('article[data-id="' + listing.id() + '"]', html)) for listing in listings
      callback() if callback
    .error () =>
      error_callback() if error_callback

  updateListing: (listing, callback) ->
    @triggerListingsRequest([listing]).success (html) =>
      listing.setHtml(html)
      callback() if callback

  triggerListingsRequest: (listings) =>
    listing_ids = (listing.id() for listing in listings).toString()
    $.ajax(
      url  : '/search/show/' + listing_ids + '?v=map'
      type : 'GET'
    )

  # Trigger automatic updating of search results
  fieldChanged: (field, value) ->
    @loader.show()
    @triggerSearchFromQueryAfterDelay()

  updateUrlForSearchQuery: ->
    url = document.location.href.replace(/\?.*$/, "")
    params = @getSearchParams()
    # we need to decodeURIComponent, otherwise accents will not be handled correctly. Remove decodeURICompoent if we switch back
    # to window.history.replaceState, but it's *absolutely mandatory* in this case. Removing it now will lead to infiite redirection in IE lte 9
    url = decodeURIComponent("?#{$.param(params)}")
    History.replaceState(params, "Search Results", url)

  updateLinksForSearchQuery: ->
    url = document.location.href.replace(/\?.*$/, "")
    params = @getSearchParams()

    $('.list-map-toggle a', @form).each ->
      for k, param of params
        if param["name"] == 'v'
          param["value"] = (if $(this).hasClass('map') then 'map' else 'list')
      _url = "#{url}?#{$.param(params)}&ignore_search_event=1"
      $(this).attr('href', _url)
    
  updateFiltersBasedOnListingsIds: ->
    for filter_wrapper in $('[data-filter]')
      div_with_listing_ids = $("[data-#{$(filter_wrapper).data('div-cached-listings-ids')}]")
      if div_with_listing_ids.length > 0
        result_listing_ids = div_with_listing_ids.data('ids')
        for filter_option in $(filter_wrapper).find('input[data-listings-ids]')
          intersection_count = (_.intersection result_listing_ids, $(filter_option).data('listings-ids')).length
          $(filter_option).siblings('.count').html("(#{intersection_count})")
          if intersection_count == 0 && !$(filter_option).prop('checked')
            $(filter_option).closest('.filter-option').hide()
          else
            $(filter_option).closest('.filter-option').show()
      else
        for filter_option in $(filter_wrapper).find('input[data-listings-ids]')
          $(filter_option).siblings('.count').html("(#{0})")
          if $(filter_option).prop('checked')
            $(filter_option).closest('.filter-option').show()
          else
            $(filter_option).closest('.filter-option').hide()
