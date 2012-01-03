# livelist.js

A client-side library for building paginated, filterable
and searchable lists.

## Dependencies

* [jQuery] (http://jquery.com)
* [mustache.js] (http://github.com/janl/mustache.js)
* [underscore.js] (http://documentcloud.github.com/underscore)

## Rails integration

livelist.js works well with Rails 3.1, see the [livelist-rails]
(http://github.com/pklingem/livelist-rails) gem

## Setup

include mustache.js, underscore.js and livelist.js on your page

in your application's javascript/coffeescript file, create a livelist:

### javascript

    $(document).ready(function(){
      list = new LiveList({
        global: {
          resourceName: 'users',
          resourceNameSingular: 'user'
        },
        list: {
          renderTo: 'ul#users',
          listItemTemplate: '<li>{{first_name}} {{last_name}} ({{status}})</li>'
        },
        filters: {
          renderTo: 'div#filters'
        },
        pagination: {
          renderTo: 'div#pagination'
        }
      })
    })

### coffeescript

    $(document).ready ->
      list = new LiveList(
        global:
          resourceName: 'users'
          resourceNameSingular: 'user'
        list:
          renderTo: 'ul#users'
          listItemTemplate: '<li>{{first_name}} {{last_name}} ({{status}})</li>'
        filters:
          renderTo: 'div#filters'
        pagination:
          renderTo: 'div#pagination'
      )

when the page loads, livelist will make an initial AJAX request to your server
to retrieve the first page of the list, the pagination details and the filter details.
The response from the server should be formatted as follows:

### initial request response JSON

    {
      'pagination': {
        'total_pages': 4,
        'current_page': 1,
        'next_page': 2,
        'previous_page': null
      },
      'filters': {
        'filter_slug': 'state',
        'filter_name': 'State',
        'options': [
          {
            'slug': 'Virginia',
            'name': 'Virginia',
            'value': 'Virginia',
            'count': 2,
            'selected': true
          }
          ...
        ]
      },
      'users': [
        {
          'user': {
            'name': 'Tim Timson'
          }
          ...
        }
      ]
    }

## Configuration

livelist.js is completely configurable; each of the properties and
functions defined in the List, Filters, Pagination and Search classes
can be overridden when instantiating a LiveList object.  For example to
override the HTTP method used when updating a list, add the httpMethod
property to the list configuration as follows:

    list = new LiveList(
      global:
        resourceName: 'users'
        resourceNameSingular: 'user'
      list:
        httpMethod: 'get'
        renderTo: 'ul#users'
        listItemTemplate: '<li>{{first_name}} {{last_name}} ({{status}})</li>'
      filters:
        renderTo: 'div#filters'
      pagination:
        renderTo: 'div#pagination'
    )

## Todos

* Calculate next and previous pages based on total_pages and
current_page in the JSON response.
* Calculate slug and value for filter options from the option name if
either aren't provided.
* Make template engine plugable (hogan.js, etc. rather than mustache)
