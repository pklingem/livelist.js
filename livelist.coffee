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

    $(@renderTo).bind(@eventName, (event, params) => @fetch(filterPresets: null, page: params?.page))
    @fetch(filterPresets: @filters.presets)

  displayFetchingIndication: => $(@renderTo).addClass(@fetchingIndicationClass)
  removeFetchingIndication:  => $(@renderTo).removeClass(@fetchingIndicationClass)

  renderIndex: (data, textStatus, jqXHR) =>
    @data = data
    @render()
    @pagination.render(@data)
    @filters.filters = _.pluck( @data.filters, 'filter_slug' )
    @filters.render(@data)

  fetch: (options) ->
    @fetchRequest.abort() if @fetchRequest
    searchTerm = @search.searchTerm()
    params = { filters: {} }
    if options.filterPresets?.length > 0
      params.filters = options.filterPresets
    else
      _.each( @filters.filters, (filter) => params.filters[filter] = @filters.filterSelections( filter ) )
    if searchTerm then params.q = searchTerm
    if options.page then params.page = options.page
    @fetchRequest = $.ajax(
      url: @urlPrefix
      dataType: 'json'
      data: params
      type: @httpMethod
      beforeSend: @displayFetchingIndication
      success: @renderIndex
    )

  render: ->
    partials = {}
    partials[@resourceNameSingular] = @listItemTemplate
    $(@renderTo).html( Mustache.to_html(@listTemplate, @data, partials) )
    @removeFetchingIndication()

class window.Filters extends Utilities
  constructor: (globalOptions, options = {}) ->
    @setOptions(globalOptions)
    @filters = if options.presets then _.keys(options.presets) else []
    @setOptions(options)
    $('input.filter_option', @renderTo).live( 'change', => $(@listSelector).trigger(@eventName) )
    $(@advancedOptionsToggleSelector).click(@handleAdvancedOptionsClick)

  filtersTemplate: '''
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

  filterValues:     (filter) -> _.pluck( $(".#{filter}_filter_input"), 'value' )
  filterSelections: (filter) -> _.pluck( $("##{filter}_filter_options input.filter_option:checked"), 'value' )

  render: (data) -> $(@renderTo).html( Mustache.to_html(@filtersTemplate, data) )

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
    $(@renderTo).html( Mustache.to_html(@paginationTemplate, @pagination) )

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
