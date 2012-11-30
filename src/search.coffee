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
