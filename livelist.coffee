class window.Utilities
  setOptions: (options, context=@) =>
    _.each( options, (value, option) => context[option] = value )

class window.LiveList extends Utilities
  constructor: (options) ->
    @listSelector         = options.list.renderTo
    @resourceName         = options.global.resourceName
    @resourceNameSingular = options.global.resourceNameSingular
    @eventName            = "livelist:#{@resourceName}"
    @urlPrefix            = "/#{@resourceName}"
    @search               = new Search(options.search, @)
    @filters              = new Filters(options.filters, @)
    @pagination           = new Pagination(options.pagination, @)
    @list                 = new List(options.list, @)

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

window.LiveList.version = '0.0.6'

class window.Filters extends Utilities
  constructor: (options, livelist) ->
    @livelist = livelist
    @filters = if options.presets then _.keys(options.presets) else []
    @initializeCookies()
    @setOptions(options)

    $('input.filter_option', @renderTo).live( 'change', => $(@livelist.listSelector).trigger(@livelist.eventName) )
    $(@advancedOptionsToggleSelector).click(@handleAdvancedOptionsClick)

  initializeCookies: ->
    if jQuery.cookie && @useCookies && @cookieName
      @cookieName = 'livelist_filter_presets'

  getPresets: ->
    cookie = jQuery.cookie(@cookieName) if jQuery.cookie && @useCookies
    if @useCookies && cookie
      JSON.parse(cookie)
    else
      @presets

  setPresets: (presets) ->
    filters = {}
    if jQuery.isEmptyObject(presets)
      filters = @selections()
      @setCookie(filters) if jQuery.cookie
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

  sortOptions: (filters) ->
    _.map( filters, (filter) ->
      filter.options = _.sortBy( filter.options, (option) -> option.name)
      filter
    )

  sort: (filters) ->
    _.sortBy( filters, (filter) -> filter.name )

  render: (data) ->
    #What is this for?
    @filters = _.pluck( data.filters, 'filter_slug' )

    @sort(data.filters)
    @sortOptions(data.filters)

    filtersHTML = Mustache.to_html(@template, data)
    $(@renderTo).html( filtersHTML )
    if @noFiltersSelected(data) && data[@livelist.resourceName].length > 0
      $('input[type="checkbox"]', @renderTo).attr('checked', 'checked')


  handleAdvancedOptionsClick: (event) =>
    event.preventDefault()
    $(@renderTo).slideToggle()

class window.Pagination extends Utilities
  constructor: (options, livelist) ->
    @livelist = livelist
    @pagination = null
    @maxPages   = 30

    @emptyListMessage = "<p>No #{@livelist.resourceName} matched your filter criteria</p>"
    @setOptions(options)

    $("#{@renderTo} a").live( 'click', (event) -> event.preventDefault() )
    $("#{@renderTo} li:not(.disabled) a").live('click', @handlePaginationLinkClick)

  template: '''
    {{#isEmpty}}
      {{{emptyListMessage}}}
    {{/isEmpty}}
    {{^isEmpty}}
    <div class="pagination">
      <ul>
        <li class="{{^previousPage}}disabled{{/previousPage}}">
          <a href='{{urlPrefix}}?page={{previousPage}}' data-page='{{previousPage}}'>← Previous</a>
        </li>

        {{#pages}}
          <li class="{{#currentPage}}active disabled{{/currentPage}}">
            <a href='{{urlPrefix}}?page={{page}}' data-page='{{page}}'>{{page}}</a>
          </li>
        {{/pages}}

        <li class="{{^nextPage}}disabled{{/nextPage}}">
          <a href='{{urlPrefix}}?page={{nextPage}}' data-page='{{nextPage}}'>Next →</a>
        </li>
      </ul>
    </div>
    {{/isEmpty}}
  '''

  pagesJSON: (currentPage, totalPages) ->
    groupSize = Math.floor(@maxPages / 2)
    firstPage = if currentPage <= groupSize then 1 else currentPage - groupSize
    previousPage = firstPage + groupSize * 2 - 1
    lastPage  = if previousPage >= totalPages then totalPages else previousPage
    _.map([firstPage..lastPage], (page) ->
      page: page
      currentPage: currentPage is page
    )

  paginationJSON: (pagination) ->
    {
      isEmpty          : pagination.total_pages == 0
      emptyListMessage : @emptyListMessage
      currentPage      : pagination.current_page
      nextPage         : pagination.next_page
      previousPage     : pagination.previous_page
      urlPrefix        : @livelist.urlPrefix
      pages            : @pagesJSON(pagination.current_page, pagination.total_pages)
    }

  render: (data) ->
    @pagination = @paginationJSON(data.pagination)
    paginationHTML = Mustache.to_html(@template, @pagination)
    $(@renderTo).html( paginationHTML )

  handlePaginationLinkClick: (event) =>
    event.preventDefault()
    $(@livelist.listSelector).trigger(@livelist.eventName, {page: $(event.target).data('page')})

class window.Search extends Utilities
  constructor: (options, livelist) ->
    @livelist = livelist
    @setOptions(options)
    $(@formSelector).submit( (event) => @handleSearchFormSubmit(event) )

  searchTerm: ->
    q = $(@searchTextInputSelector).val()
    if !q or (q is '') then null else q

  handleSearchFormSubmit: (event) =>
    event.preventDefault()
    $(@livelist.listSelector).trigger(@livelist.eventName)
