class @Space.Controller

  constructor: (@container, @options = {}) ->
    @setupCollapse()
    @setupCarousel()
    @setupMap()
    @setupPhotos()
    @setupBookings()
    @_bindEvents()

  _bindEvents: ->
    @container.on 'click', '[data-behavior=scrollToBook]', (event) =>
      event.preventDefault()
      $('html, body').animate({
        scrollTop: $(".bookings").offset().top - 20
      }, 300)

  setupPhotos: ->
    @photos = new Space.PhotosController($('.space-hero-photos'))

  setupBookings: ->
    @bookings = new Space.BookingManager(@container.find('.bookings'), @options.bookings)

  setupMap: ->
    mapContainer = $(".map")
    return unless mapContainer.length > 0

    location = mapContainer.find('address')
    latlng = new google.maps.LatLng(
      location.attr("data-lat"), location.attr("data-lng")
    )

    @map = { map: null, markers: [] }
    @map.map = new google.maps.Map(mapContainer.find('.map-container')[0], {
      zoom: 13,
      mapTypeControl: false,
      streetViewControl: false,
      center: latlng,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    })

    @map.markers.push new google.maps.Marker({
      position: latlng,
      map: @map.map,
      icon: location.attr("data-marker")
    })

  setupCarousel: ->
    carouselContainer = $(".carousel")
    return unless carouselContainer.length > 0
    carouselContainer.carousel({
      pills: true,
      interval: 10000
    })

  setupCollapse: ->
    collapseContainer = $(".accordion")
    return unless collapseContainer.length > 0
    collapseContainer.collapse()


