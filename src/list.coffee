class window.List extends Utilities
  constructor: (options, livelist) ->
    @fetchRequest = null
    @livelist     = livelist

    @listTemplate            = "{{##{@livelist.resourceName}}}{{>#{@livelist.resourceNameSingular}}}{{/#{@livelist.resourceName}}}"
    @listItemTemplate        = '<li>{{id}}</li>'
    @fetchingIndicationClass = 'updating'
    @renderTo                = "ul##{@livelist.resourceName}"

    @setOptions(options)

    $(@renderTo).bind(@livelist.eventName, (event, params) => @fetch(presets: null, page: params?.page))
    @fetch(presets: @livelist.filters.getPresets())

  displayFetchingIndication: => $(@renderTo).addClass(@fetchingIndicationClass)
  removeFetchingIndication:  => $(@renderTo).removeClass(@fetchingIndicationClass)

  renderIndex: (data, textStatus, jqXHR) =>
    @livelist.data = data
    @render()
    @livelist.pagination.render(@livelist.data)
    @livelist.filters.render(@livelist.data)

  fetch: (options) ->
    @fetchRequest.abort() if @fetchRequest
    searchTerm = @livelist.search.searchTerm()
    params = {}
    params.filters = @livelist.filters.setPresets(options.presets)

    if searchTerm
      params.q = searchTerm
    if options.page
      params.page = options.page

    @fetchRequest = $.ajax(
      url         : @livelist.urlPrefix
      type        : @livelist.httpMethod
      dataType    : 'json'
      data        : params
      beforeSend  : @displayFetchingIndication
      success     : @renderIndex
    )

  render: ->
    partials = {}
    partials[@livelist.resourceNameSingular] = @listItemTemplate
    listHTML = Mustache.to_html(@listTemplate, @livelist.data, partials)
    $(@renderTo).html( listHTML )
    @removeFetchingIndication()
