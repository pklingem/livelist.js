class window.LiveList extends Utilities
  constructor: (options) ->
    @listSelector         = options.list.renderTo
    @resourceName         = options.global.resourceName
    @resourceNameSingular = options.global.resourceNameSingular
    @urlPrefix            = options.global.urlPrefix || "/#{@resourceName}"
    @httpMethod           = options.global.httpMethod || 'get'
    @eventName            = "livelist:#{@resourceName}"
    @search               = new Search(options.search, @)
    @filters              = new Filters(options.filters, @)
    @pagination           = new Pagination(options.pagination, @)
    @list                 = new List(options.list, @)
