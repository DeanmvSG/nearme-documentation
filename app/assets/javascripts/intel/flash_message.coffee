class @FlashMessage
  constructor: (el)->
    @message = $(el)
    @initStructure()
    @addEventListeners()

  initStructure: ->
    closeLabel = @message.data('close-label')
    btn = $("<button type='button' class='close' title='#{closeLabel}'><span class='intelicon-close-solid'></span></button>")
    @message.find('.contain').append(btn)

  addEventListeners: ->
    @message.on 'click', '.close', =>
      @message.slideUp()

  @initialize: ()->
    $('[data-flash-message]').each ()->
      new FlashMessage(this)
