class @UI
  constructor: ()->

  # makes elements with data-equalize attribute the same height
  @equalize: ()->
    prop = if !document.addEventListener then 'height' else 'outerHeight'
    $('[data-equalize]').vEqualize(height: prop)

  # toggle navigation visibility
  @nav: ()->
    body = $('body')
    $('[data-nav]').on 'click', (event) ->
      event.preventDefault()
      body.toggleClass 'is-nav'

  # expand read more sections
  @readmore: ()->
    $('body').on 'click', '.readmore-a', (event) ->
      event.preventDefault()
      $(this).addClass 'is-active'

  # toggles visibility of the comment form
  @toggleCommentForm: ()->
    $('[data-comment]').on "click", (event) ->
      event.preventDefault()
      $(this).closest('footer').find('> .comment').toggleClass 'is-active'


  # init tinyNav for tabs navigation
  @tabsStatic: ()->
    $('.tabs-a ul:not(.nav-tabs)').tinyNav active: 'is-active'

  @tabsDynamic: ()->
    $('.tabs-a ul.nav-tabs').each ()->
      list = $(this)
      tabs = list.find('[role="tab"]')

      select = $('<select/>')
      tabs.each ()->
        option = $('<option>',{
          value: $(this).attr('href')
          text: $(this).text()
        })
        option.appendTo(select)

      select.on 'change', (e)->
        href = $(this).val()
        tabs.filter('[href="' + href + '"]').tab('show')

      tabs.on 'click', (e)->
        href = $(this).attr('href')
        select.val(href)

      list.after(select)

  @initialize: ()->
    @equalize()
    @nav()
    @readmore()
    @toggleCommentForm()
    @tabsStatic()
    @tabsDynamic()


