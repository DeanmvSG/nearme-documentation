class @Space.Controller

  constructor: (@container, @options = {}) ->
    @mapAndPhotosContainer = $('.location-photos')
    @photosContainer = $('.photos-container')
    @mapContainer    = $('.map')
    @googleMapElementWrapper = @mapContainer.find('.map-container')
    @siblingListingsCarousel = @container.find('#listing-siblings-container')
    @fullScreenGallery = @container.find('#photos-container-enlarged')
    @fullScreenGalleryTrigger = @container.find('button[data-gallery-enlarge]') 
    @fullScreenGalleryContainer = @container.find('#fullscreen-gallery')

    @setupCollapse()
    @setupCarousel()
    @setupMap()
    @setupPhotos()
    @setupBookings()
    @_bindEvents()
    @adjustBookingModulePosition()
    @adjustFullGalleryHeight()

  _bindEvents: ->
    @container.on 'click', '[data-behavior=scrollToBook]', (event) =>
      event.preventDefault()
      $('html, body').animate({
        scrollTop: $(".bookings").offset().top - 20
      }, 300)

    $(window).resize =>
      @adjustBookingModulePosition()
      @adjustFullGalleryHeight()

    @siblingListingsCarousel.on 'slid.bs.carousel', =>
      currentSlide = @siblingListingsCarousel.find('.item.active').eq(0)
      @container.find('.other-listings header p a').text(currentSlide.data('listing-name')).attr('href', currentSlide.data('listing-url'))

    @fullScreenGalleryTrigger.on 'click', =>
      setTimeout ( =>
        @adjustFullGalleryHeight()
      ), 1200

    @fullScreenGalleryContainer.on "show", (e) =>
      @loadFullGalleryPhotos()

    @container.on 'click', '.amenities-header a', (event) =>
      @toggleAmenities(event)

    @container.on 'click', '[data-booking-trigger]', (event) =>
      $(event.target).closest('[data-toggleable-booking-module]').toggleClass('collapsed')
      false

  loadFullGalleryPhotos: ->
    @fullScreenGalleryContainer.find(".loading").show()
    carousel = $(this).find(".carousel").hide()
    deferreds = []
    imgs = @fullScreenGalleryContainer.find(".carousel .item", this).find("img")

    # loop over each img
    imgs.each ->
      self = $(this)
      datasrc = self.attr("data-src")
      if datasrc
        d = $.Deferred()
        self.one("load", d.resolve).attr("src", datasrc).attr "data-src", ""
        deferreds.push d.promise()

    $.when.apply($, deferreds).done =>
      @fullScreenGalleryContainer.find(".loading").hide()
      carousel.fadeIn 1000


  adjustBookingModulePosition: ->
    # 610 - booking module breakpoint
    if $(window).width() <= 610
      # move booking module below photos gallery and add some padding
      @container.find('.listings').addClass('padding-row').appendTo(@container.find('article.photos'))
    else
      @container.find('.listings').removeClass('padding-row').appendTo(@container.find('article.booking'))

  adjustFullGalleryHeight: ->
    @fullScreenGallery.find('.item img').removeClass('smaller-size')
    if @fullScreenGallery.find('.item.active img').height() >= $(window).height()
      @fullScreenGallery.height($(window).height())
      @fullScreenGallery.find('.item img').addClass('smaller-size')
    else
      @fullScreenGallery.height('auto')

  setupPhotos: ->
    @photos = new Space.PhotosController($('.space-hero-photos'))

  setupBookings: ->
    # For each listing on the page, initialize a controller for handling booking
    # selection.
    for listingData in @options.bookings.listings
      listingController = new Bookings.Controller(@container.find("div[data-listing-id=#{listingData.id}]"),
        listingData,
        showReviewBookingImmediately: @options.bookings.returnedFromSession
      )

  setupMap: ->
    return unless @mapContainer.length > 0

    location = @mapContainer.find('address')
    latlng = new google.maps.LatLng(
      location.attr("data-lat"), location.attr("data-lng")
    )

    mapTypeId = google.maps.MapTypeId.ROADMAP

    @map = { map: null, markers: [] }
    @map.initialCenter = latlng
    @map.map = SmartGoogleMap.createMap(@googleMapElementWrapper[0], {
      zoom: 13,
      zoomControlOptions: {
          style:google.maps.ZoomControlStyle.SMALL
      },
      mapTypeControl: false,
      panControl: false,
      streetViewControl: false,
      center: latlng,
      mapTypeId: mapTypeId
    })

    marker =  new google.maps.Marker({
      position: latlng,
      map: @map.map,
      icon: GoogleMapMarker.getMarkerOptions().default.image,
      shadow: null,
      shape: GoogleMapMarker.getMarkerOptions().default.shape
    })

    @map.markers.push marker

    @popover = new GoogleMapPopover({'boxStyle': { 'width': '190px' }, 'pixelOffset': new google.maps.Size(-95, -40) })
    @popover.setContent @mapContainer.find('address').html()
    if ($.browser.msie && parseInt($.browser.version) > 9)
      @popover.open(@map.map, marker)

    google.maps.event.addListener marker, 'click', =>
      @popover.open(@map.map, marker)


  setupCarousel: ->
    carouselContainer = $(".carousel")
    return unless carouselContainer.length > 0
    carouselContainer.carousel({
      pills: false,
      wrap: true,
      interval: 10000
    })

  setupCollapse: ->
    collapseContainer = $(".accordion")
    return unless collapseContainer.length > 0
    collapseContainer.on('show hide', -> $(this).css('height', 'auto') )
    collapseContainer.collapse({ parent: true, toggle: true })

  toggleAmenities: (event) ->
    amenities_header = $(event.target).closest('.amenities-header')
    amenities_block = amenities_header.closest('.amenities-block')
    amenities_header.find('a span').toggleClass('ico-chevron-right').toggleClass('ico-chevron-down')
    amenities_block.toggleClass('amenities-shown')
    false
