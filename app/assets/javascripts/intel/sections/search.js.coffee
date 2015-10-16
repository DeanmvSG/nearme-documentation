class @Search
  constructor: (@form) ->
    @queryInput ||= => $('input#_query');
    @pageInput ||= => @form.find('input#_page');
    @topnavForm = $('form#search_topnav')
    @topnavFormQuery = $('#topnav_query')
    @searchTabs = $('nav.search-types a')
    @paginationContainer = $('.pagination-more-a')
    @seeMoreLink ||= => @paginationContainer.find('p.more-a');
    @searchContainer ||= =>  $('.search-container')
    @searchResults ||= =>  $('.search-results')
    @bindEvents()

  bindEvents: ->
    @bindForm()

    @topnavForm.on 'submit', (event) =>
      event.preventDefault()
      @triggerSearchAndHandleResults()

    @paginationContainer.on 'click', (event) =>
      event.preventDefault()
      @getNextPage()

    @searchTabs.on 'click', (event) =>
      event.preventDefault()
      @triggerTabSwitchAndHandleResults($(event.target))

  bindForm: ->
    @form = $('form#search_filter')
    @form.on 'change', =>
      @triggerSearchAndHandleResults()

  getNextPage: ->
    page = @seeMoreLink().data('next-page')
    if page
      @pageInput().val(page)

    @triggerSearchRequest().success (html) =>
      @appendResults(html)
      @replaceSeeMore(html)
    true

  triggerTabSwitchAndHandleResults: (tab) ->
    tab.parents('ul').find('li.is-active').removeClass('is-active')
    tab.parents('li').addClass('is-active')
    data = { search_type: tab.data('search-type'), query: @topnavFormQuery.val(), page: 1 }
    @triggerSearchAndHandleResults(data)


# Triggers a search with default UX behaviour and semantics.
  triggerSearchAndHandleResults: (data) ->
    @queryInput().val(@topnavFormQuery.val())
    @pageInput().val(1)
    @triggerSearchRequest(data).success (html) =>
      @showResults(html)
      @reinitializeElements()
      @replaceSeeMore(html)
      @updateUrlForSearchQuery()

  showResults: (html) ->
    @searchContainer().replaceWith($(html).find('.search-container'))

  appendResults: (html) ->
    @searchResults().append($(html).find('.search-results').html())
    #$('.pagination').hide()

  replaceSeeMore: (html) ->
    if $(html).find('.pagination-more-a').length > 0
      @paginationContainer.show()
      @paginationContainer.html($(html).find('.pagination-more-a').html())
    else
      @paginationContainer.hide()

  reinitializeElements: ->
    window.Forms.selectize()
    @bindForm()


  # Trigger the API request for search
  #
  # Returns a jQuery Promise object which can be bound to execute response semantics.
  triggerSearchRequest: (data) ->
    data = @form.serialize() unless data
    $.ajax(
      url  : @form.attr("action")
      type : 'GET',
      data : data
    )


  updateUrlForSearchQuery: ->
    url = document.location.href.replace(/\?.*$/, "")
    params = @getSearchParams()
    # we need to decodeURIComponent, otherwise accents will not be handled correctly. Remove decodeURICompoent if we switch back
    # to window.history.replaceState, but it's *absolutely mandatory* in this case. Removing it now will lead to infiite redirection in IE lte 9
    url = decodeURIComponent("?#{$.param(params)}")
    for tab in @searchTabs
      old_url = $(tab).attr('href').split('?')[0]
      $(tab).attr('href', old_url + "?query=#{@topnavFormQuery.val()}")
    History.replaceState(params, "Search Results", url)


  getSearchParams: ->
    form_params = @form.serializeArray()
    # don't polute url if this is unnecessary - ignore empty values and page
    params = []
    for k, param of form_params
      if param["name"] != 'page' && param["name"] != 'authenticity_token' && param["value"] != ''
        params.push(param)
    params
