# Controller for Adding JS for each search result in 'list' view
#
class Search.SearchResultsGoogleMapController

  constructor: (@container, @googleMapWrapper) ->
      @map = @initializeGoogleMap()
      @container.on 'mouseenter', '.photo-container', (event) =>
        element = $(event.target).closest('.listing')
        elementsGoogleMapWrapper = element.find('.listing-google-map')
        @googleMapWrapper.appendTo(elementsGoogleMapWrapper)
        latlng = new google.maps.LatLng(element.data('latitude'), element.data('longitude'))
        @map.marker.setPosition(latlng)
        element.find('.listing-google-map-wrapper').show()
        google.maps.event.trigger(@map, "resize")
        @map.setCenter(@map.marker.getPosition())
      @container.on 'mouseleave', '.photo-container', (event) =>
        element = $(event.target).closest('.listing')
        elementsGoogleMapWrapper = element.find('.listing-google-map')
        element.find('.listing-google-map-wrapper').hide()

  @bindToolTip: (result) ->
      result.find('.connections').tooltip(html: true, placement: 'top')

  initializeGoogleMap: ->
      map = SmartGoogleMap.createMap(@googleMapWrapper.get(0), {
        zoom: 14,
        zoomControl: true,
        mapTypeControl: false,
        streetViewControl: false,
        mapTypeId: google.maps.MapTypeId.ROADMAP
      })

      map.marker = new google.maps.Marker({
        map: map,
        icon: @googleMapWrapper.attr("data-marker"),
        draggable: false
      })

      map
