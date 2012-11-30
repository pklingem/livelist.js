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
