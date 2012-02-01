class window.Utilities
  setOptions: (options, context=@) =>
    _.each( options, (value, option) => context[option] = value )

class window.LiveList extends Utilities
  constructor: (options) ->
    @globalOptions.listSelector = options.list.renderTo
    @globalOptions.eventName    = "livelist:#{options.global.resourceName}"
    @globalOptions.urlPrefix    = "/#{options.global.resourceName}"

    @setOptions(options.global, @globalOptions)

    @search     = new Search(@globalOptions, options.search)
    @filters    = new Filters(@globalOptions, options.filters)
    @pagination = new Pagination(@globalOptions, options.pagination)
    @list       = new List(@search, @filters, @pagination, @globalOptions, options.list)

  globalOptions:
    data: null
    resourceName: 'items'
    resourceNameSingular: 'item'

class window.List extends Utilities
  constructor: (search, filters, pagination, globalOptions, options = {}) ->
    @data         = globalOptions.data
    @fetchRequest = null
    @search       = search
    @filters      = filters
    @pagination   = pagination

    @setOptions(globalOptions)
    @listTemplate            = "{{##{@resourceName}}}{{>#{@resourceNameSingular}}}{{/#{@resourceName}}}"
    @listItemTemplate        = '<li>{{id}}</li>'
    @fetchingIndicationClass = 'updating'
    @setOptions(options)

    $(@renderTo).bind(@eventName, (event, params) => @fetch(presets: null, page: params?.page))

    presets = @filters.presets()
    @fetch(presets: presets)

  displayFetchingIndication: => $(@renderTo).addClass(@fetchingIndicationClass)
  removeFetchingIndication:  => $(@renderTo).removeClass(@fetchingIndicationClass)

  renderIndex: (data, textStatus, jqXHR) =>
    @data = data
    @render()
    @pagination.render(@data)
    @filters.render(@data)

  fetch: (options) ->
    @fetchRequest.abort() if @fetchRequest
    searchTerm = @search.searchTerm()
    params = {}
    params.filters = @filters.setPresets(options.presets)

    if searchTerm
      params.q = searchTerm
    if options.page
      params.page = options.page

    @fetchRequest = $.ajax(
      url         : @urlPrefix
      dataType    : 'json'
      data        : params
      type        : @httpMethod
      beforeSend  : @displayFetchingIndication
      success     : @renderIndex
    )

  render: ->
    partials = {}
    partials[@resourceNameSingular] = @listItemTemplate
    listHTML = Mustache.to_html(@listTemplate, @data, partials)
    $(@renderTo).html( listHTML )
    @removeFetchingIndication()

window.LiveList.version = '0.0.4'

class window.Filters extends Utilities
  constructor: (globalOptions, options = {}) ->
    @setOptions(globalOptions)
    @filters = if options.presets then _.keys(options.presets) else []
    @initializeCookies()
    @setOptions(options)
    $('input.filter_option', @renderTo).live( 'change', => $(@listSelector).trigger(@eventName) )
    $(@advancedOptionsToggleSelector).click(@handleAdvancedOptionsClick)

  initializeCookies: ->
    if jQuery.cookie && @useCookies && @cookieName
      @cookieName = 'livelist_filter_presets'

  presets: ->
    cookie = jQuery.cookie(@cookieName) if jQuery.cookie && @useCookies
    if @useCookies && cookie
      JSON.parse(cookie)
    else
      @presets

  setPresets: (presets) ->
    filters = {}
    if jQuery.isEmptyObject(presets)
      filters = @selections()
      @setCookie() if jQuery.cookie
    else
      filters = presets
    filters

  setCookie: (params_filters) ->
    if not jQuery.isEmptyObject(params_filters)
      jQuery.cookie(@cookieName, JSON.stringify(params_filters))

  template: '''
    {{#filters}}
    <div class='filter'>
      <h3>
        {{name}}
      </h3>
      <ul id='{{filter_slug}}_filter_options'>
        {{#options}}
        <label>
          <li>
            <input {{#selected}}checked='checked'{{/selected}}
                   class='left filter_option'
                   id='filter_{{slug}}'
                   name='filters[]'
                   type='checkbox'
                   value='{{value}}' />
            <div class='left filter_name'>{{name}}</div>
            <div class='right filter_count'>{{count}}</div>
            <div class='clear'></div>
          </li>
        </label>
        {{/options}}
      </ul>
    </div>
    {{/filters}}
  '''

  selections: ->
    filters = {}
    _.each( @filters, (filter) =>
      filters[filter] = _.pluck( $("##{filter}_filter_options input.filter_option:checked"), 'value' )
    )
    filters

  noFiltersSelected: (data) ->
    _.all( data.filters, (filter) ->
      _.all( filter.options, (option) ->
        not option.selected
      )
    )

  render: (data) ->
    @filters = _.pluck( data.filters, 'filter_slug' )
    filtersHTML = Mustache.to_html(@template, data)
    $(@renderTo).html( filtersHTML )
    if @noFiltersSelected(data) && data[@resourceName].length > 0
      $('input[type="checkbox"]', @renderTo).attr('checked', 'checked')


  handleAdvancedOptionsClick: (event) =>
    event.preventDefault()
    $(@renderTo).slideToggle()

class window.Pagination extends Utilities
  constructor: (globalOptions, options = {}) ->
    @pagination = null
    @maxPages   = 30

    @setOptions(globalOptions)
    @emptyListMessage = "<p>No #{@resourceName} matched your filter criteria</p>"
    @setOptions(options)

    $("#{@renderTo} a").live('click', @handlePaginationLinkClick)

  paginationTemplate: '''
    {{#isEmpty}}
      {{{emptyListMessage}}}
    {{/isEmpty}}
    {{^isEmpty}}
    {{#previousPage}}
      <a href='{{urlPrefix}}?page={{previousPage}}' data-page='{{previousPage}}'>← Previous</a>
    {{/previousPage}}
    {{^previousPage}}
      <span>← Previous</span>
    {{/previousPage}}
    {{#pages}}
      {{#currentPage}}
        <span>{{page}}</span>
      {{/currentPage}}
      {{^currentPage}}
        <a href='{{urlPrefix}}?page={{page}}' data-page='{{page}}'>{{page}}</a>
      {{/currentPage}}
    {{/pages}}
    {{#nextPage}}
      <a href='{{urlPrefix}}?page={{nextPage}}' data-page='{{nextPage}}'>Next →</a>
    {{/nextPage}}
    {{^nextPage}}
      <span>Next →</span>
    {{/nextPage}}
    {{/isEmpty}}
  '''

  pagesJSON: (currentPage, totalPages) ->
    groupSize = @maxPages / 2
    firstPage = if currentPage < groupSize then 1 else currentPage - groupSize
    previousPage = firstPage + groupSize * 2 - 1
    lastPage  = if previousPage >= totalPages then totalPages else previousPage
    _.map([firstPage..lastPage], (page) ->
      page: page
      currentPage: -> currentPage is page
    )

  paginationJSON: (pagination) ->
    {
      isEmpty          : pagination.total_pages == 0
      emptyListMessage : @emptyListMessage
      currentPage      : pagination.current_page
      nextPage         : pagination.next_page
      previousPage     : pagination.previous_page
      urlPrefix        : @urlPrefix
      pages            : @pagesJSON(pagination.current_page, pagination.total_pages)
    }

  render: (data) ->
    @pagination = @paginationJSON(data.pagination)
    paginationHTML = Mustache.to_html(@paginationTemplate, @pagination)
    $(@renderTo).html( paginationHTML )

  handlePaginationLinkClick: (event) =>
    event.preventDefault()
    $(@listSelector).trigger(@eventName, {page: $(event.target).data('page')})

class window.Search extends Utilities
  constructor: (globalOptions, options = {}) ->
    @setOptions(globalOptions)
    @setOptions(options)
    $(@formSelector).submit( (event) => @handleSearchFormSubmit(event) )

  searchTerm: ->
    q = $(@searchTextInputSelector).val()
    if !q or (q is '') then null else q

  handleSearchFormSubmit: (event) =>
    event.preventDefault()
    $(@listSelector).trigger(@eventName)
