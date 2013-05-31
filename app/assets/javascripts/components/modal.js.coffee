# A simple modal implementation
#
# FIXME: Requires pre-existing HTML markup
# TODO: This is just a first-cut. We can tidy this up and allow further customisation etc.
#
# Usage:
#   # Load a URL and have Modal handle all the loading view and content showing, etc:
#   Modal.load("/my/url")
#
#   # Manually trigger the loading view of a visible modal:
#   Modal.showLoading()
#
#   # Manually update the content of a visible modal:
#   Modal.showContent("my new content")
class @Modal

  @reloadOnClose: (url) ->
    @_reloadOnClose = url

  # Listen for click events on modalized links
  # Modalized links are anchor elements with rel="modal"
  # A custom class can be specified on the modal:
  #   <a href="modalurl" rel="modal.my-class">link</a>
  @listen : ->
    $('body').delegate 'a[rel*="modal"]', 'click', (e) =>
      e.preventDefault()
      target = $(e.currentTarget)
      modalClass = matches[1] if matches = target.attr("rel").match(/modal\.([^\s]+)/)

      @load(target.attr("href"), modalClass)
      false

    $('.modal-content form').live 'ajax:before', =>
      @showLoading()

    $('.modal-content form').live 'ajax:success', (event, data) =>
      Modal.showContent(data)

  # Show the loading status on the modal
  @showLoading : ->
    @instance().showLoading()

  # Show the content on the modal
  @showContent : (content) ->
    @instance().showContent(content)

  # Trigger laoding of the URL within the modal via AJAX
  @load : (ajaxOptions, modalClass = null) ->
    @instance().setClass(modalClass)
    @instance().load(ajaxOptions)

  @load : (ajaxOptions, modalClass = null, callback = null) ->
    @instance().setClass(modalClass)
    @instance().load(ajaxOptions)
    @instance().setCallback(callback)

  @setClass: (klass) ->
    @instance().setClass(klass)

  # ===

  constructor: (@options) ->
    @container = $('.modal-container')
    @content = @container.find('.modal-content')
    @loading = @container.find('.modal-loading')
    @bodyContainer = $('.dnm-page')
    @overlay = $('.modal-overlay')

    # Bind to any element with "close" class to trigger close on the modal
    @container.delegate ".close-modal, .modal-close", 'click', (e) =>
      e.preventDefault()
      @hide()

    # Bind to the overlay to close the modal
    @overlay.bind 'click', (e) =>
      @hide()

  setCallback : (callback) ->
    @callback = callback

  setClass : (klass) ->
    @container.removeClass(@customClass) if @customClass
    
    @customClass = klass
    @container.addClass(klass) if klass

  showContent : (content) ->
    @_show()
    @container.removeClass('loading')
    @loading.hide()
    @content.html("") if content
    @content.show()
    @content.html(content) if content

    # We need to ensure there has been a reflow displaying the target element
    # before applying the class with the animation transitions
    setTimeout =>
      @content.addClass('visible')
    , 20

  showLoading : ->
    @container.addClass('loading')
    @content.hide()
    @loading.show()

  hide: ->
    @content.removeClass('visible')
    @overlay.removeClass('visible')
    @container.removeClass('visible')

    # We need to ensure our transitions have had enough time to execute
    # prior to hiding the element.
    setTimeout =>
      @overlay.hide()
      @container.hide()

      # Clear any assigned modal class
      @setClass(null)

      @_unfixBody()
      @callback() if @callback
    , 200

    # Redirect if bound
    if Modal._reloadOnClose
      window.location = Modal._reloadOnClose

  # Trigger visibility of the modal
  _show: ->
    @_fixBody()
    @overlay.show()
    @container.show()
    @positionModal()

    # We need to ensure there has been a reflow displaying the target element
    # before applying the class with the animation transitions
    setTimeout =>
      @overlay.addClass('visible')
      @container.addClass('visible')
    , 20

  # Load the given URL in the modal
  # Displays the modal, shows the loading status, fires an AJAX request and
  # displays the content
  load : (ajaxOptions) ->
    @_show()
    @showLoading()

    request = $.ajax(ajaxOptions)
    request.success (data) =>
      if data.redirect
        document.location = data.redirect
      else
        @showContent(data)

  # Position the modal on the page.
  positionModal: ->
    height = @container.height()
    windowHeight = $(window).height()
    width = @container.width()

    # FIXME: Pass these in as configuration options to the modal
    @container.css(position: 'absolute', top: '50px', left: '50%', 'margin-left': "-#{parseInt(width/2)}px")

  _bodyIsFixed: ->
    @bodyContainer.is('.modal-body-wrapper')

  # Fix the position of the main page content, preventing scrolling and allowing the window scrollbar to scroll the modal's content instead.
  _fixBody: ->
    return if @_bodyIsFixed()
    @_scrollTopWas = $(window).scrollTop()
    @bodyContainer.addClass('modal-body-wrapper').css('margin-top': "-#{@_scrollTopWas}px")
    $(window).scrollTop(0)

  # Reverse the 'fixing' of the primary page content
  _unfixBody: ->
    return unless @_bodyIsFixed()
    @bodyContainer.removeClass('modal-body-wrapper').css('margin-top': 'auto')
    $(window).scrollTop(@_scrollTopWas)

  # Get the instance of the Modal object
  @instance : ->
    window.modal ||= new Modal()

