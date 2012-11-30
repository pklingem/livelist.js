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

