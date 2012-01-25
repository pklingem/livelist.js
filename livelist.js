(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  window.Utilities = (function() {

    function Utilities() {
      this.setOptions = __bind(this.setOptions, this);
    }

    Utilities.prototype.setOptions = function(options, context) {
      var _this = this;
      if (context == null) context = this;
      return _.each(options, function(value, option) {
        return context[option] = value;
      });
    };

    return Utilities;

  })();

  window.LiveList = (function(_super) {

    __extends(LiveList, _super);

    function LiveList(options) {
      this.globalOptions.listSelector = options.list.renderTo;
      this.globalOptions.eventName = "livelist:" + options.global.resourceName;
      this.globalOptions.urlPrefix = "/" + options.global.resourceName;
      this.setOptions(options.global, this.globalOptions);
      this.search = new Search(this.globalOptions, options.search);
      this.filters = new Filters(this.globalOptions, options.filters);
      this.pagination = new Pagination(this.globalOptions, options.pagination);
      this.list = new List(this.search, this.filters, this.pagination, this.globalOptions, options.list);
    }

    LiveList.prototype.globalOptions = {
      data: null,
      resourceName: 'items',
      resourceNameSingular: 'item'
    };

    return LiveList;

  })(Utilities);

  window.List = (function(_super) {

    __extends(List, _super);

    function List(search, filters, pagination, globalOptions, options) {
      var cookie, presets,
        _this = this;
      if (options == null) options = {};
      this.renderIndex = __bind(this.renderIndex, this);
      this.removeFetchingIndication = __bind(this.removeFetchingIndication, this);
      this.displayFetchingIndication = __bind(this.displayFetchingIndication, this);
      this.data = globalOptions.data;
      this.fetchRequest = null;
      this.search = search;
      this.filters = filters;
      this.pagination = pagination;
      this.setOptions(globalOptions);
      this.listTemplate = "{{#" + this.resourceName + "}}{{>" + this.resourceNameSingular + "}}{{/" + this.resourceName + "}}";
      this.listItemTemplate = '<li>{{id}}</li>';
      this.fetchingIndicationClass = 'updating';
      this.setOptions(options);
      $(this.renderTo).bind(this.eventName, function(event, params) {
        return _this.fetch({
          presets: null,
          page: params != null ? params.page : void 0
        });
      });
      if (jQuery.cookie && this.filters.useCookies) {
        cookie = jQuery.cookie(this.filters.cookieName);
      }
      if (this.filters.useCookies && cookie) {
        presets = JSON.parse(cookie);
      } else {
        presets = this.filters.presets;
      }
      this.fetch({
        presets: presets
      });
    }

    List.prototype.displayFetchingIndication = function() {
      return $(this.renderTo).addClass(this.fetchingIndicationClass);
    };

    List.prototype.removeFetchingIndication = function() {
      return $(this.renderTo).removeClass(this.fetchingIndicationClass);
    };

    List.prototype.renderIndex = function(data, textStatus, jqXHR) {
      this.data = data;
      this.render();
      this.pagination.render(this.data);
      this.filters.filters = _.pluck(this.data.filters, 'filter_slug');
      return this.filters.render(this.data);
    };

    List.prototype.selections = function() {
      var filters,
        _this = this;
      filters = {};
      _.each(this.filters.filters, function(filter) {
        return filters[filter] = _this.filters.filterSelections(filter);
      });
      return filters;
    };

    List.prototype.fetch = function(options) {
      var params, searchTerm;
      if (this.fetchRequest) this.fetchRequest.abort();
      searchTerm = this.search.searchTerm();
      params = {
        filters: {}
      };
      if (jQuery.isEmptyObject(options.presets)) {
        params.filters = this.selections();
        if (jQuery.cookie && !jQuery.isEmptyObject(params.filters)) {
          jQuery.cookie(this.filters.cookieName, JSON.stringify(params.filters));
        }
      } else {
        params.filters = options.presets;
      }
      if (searchTerm) params.q = searchTerm;
      if (options.page) params.page = options.page;
      return this.fetchRequest = $.ajax({
        url: this.urlPrefix,
        dataType: 'json',
        data: params,
        type: this.httpMethod,
        beforeSend: this.displayFetchingIndication,
        success: this.renderIndex
      });
    };

    List.prototype.render = function() {
      var partials;
      partials = {};
      partials[this.resourceNameSingular] = this.listItemTemplate;
      $(this.renderTo).html(Mustache.to_html(this.listTemplate, this.data, partials));
      return this.removeFetchingIndication();
    };

    return List;

  })(Utilities);

  window.LiveList.version = '0.0.3';

  window.Filters = (function(_super) {

    __extends(Filters, _super);

    function Filters(globalOptions, options) {
      var _this = this;
      if (options == null) options = {};
      this.handleAdvancedOptionsClick = __bind(this.handleAdvancedOptionsClick, this);
      this.setOptions(globalOptions);
      this.filters = options.presets ? _.keys(options.presets) : [];
      if (!this.filters.cookieName) {
        this.filters.cookieName = 'livelist_filter_presets';
      }
      this.setOptions(options);
      $('input.filter_option', this.renderTo).live('change', function() {
        return $(_this.listSelector).trigger(_this.eventName);
      });
      $(this.advancedOptionsToggleSelector).click(this.handleAdvancedOptionsClick);
    }

    Filters.prototype.filtersTemplate = '{{#filters}}\n<div class=\'filter\'>\n  <h3>\n    {{name}}\n  </h3>\n  <ul id=\'{{filter_slug}}_filter_options\'>\n    {{#options}}\n    <label>\n      <li>\n        <input {{#selected}}checked=\'checked\'{{/selected}}\n               class=\'left filter_option\'\n               id=\'filter_{{slug}}\'\n               name=\'filters[]\'\n               type=\'checkbox\'\n               value=\'{{value}}\' />\n        <div class=\'left filter_name\'>{{name}}</div>\n        <div class=\'right filter_count\'>{{count}}</div>\n        <div class=\'clear\'></div>\n      </li>\n    </label>\n    {{/options}}\n  </ul>\n</div>\n{{/filters}}';

    Filters.prototype.filterValues = function(filter) {
      return _.pluck($("." + filter + "_filter_input"), 'value');
    };

    Filters.prototype.filterSelections = function(filter) {
      return _.pluck($("#" + filter + "_filter_options input.filter_option:checked"), 'value');
    };

    Filters.prototype.noFiltersSelected = function(data) {
      return _.all(data.filters, function(filter) {
        return _.all(filter.options, function(option) {
          return !option.selected;
        });
      });
    };

    Filters.prototype.render = function(data) {
      $(this.renderTo).html(Mustache.to_html(this.filtersTemplate, data));
      if (this.noFiltersSelected(data) && data[this.resourceName].length > 0) {
        return $('input[type="checkbox"]', this.renderTo).attr('checked', 'checked');
      }
    };

    Filters.prototype.handleAdvancedOptionsClick = function(event) {
      event.preventDefault();
      return $(this.renderTo).slideToggle();
    };

    return Filters;

  })(Utilities);

  window.Pagination = (function(_super) {

    __extends(Pagination, _super);

    function Pagination(globalOptions, options) {
      if (options == null) options = {};
      this.handlePaginationLinkClick = __bind(this.handlePaginationLinkClick, this);
      this.pagination = null;
      this.maxPages = 30;
      this.setOptions(globalOptions);
      this.emptyListMessage = "<p>No " + this.resourceName + " matched your filter criteria</p>";
      this.setOptions(options);
      $("" + this.renderTo + " a").live('click', this.handlePaginationLinkClick);
    }

    Pagination.prototype.paginationTemplate = '{{#isEmpty}}\n  {{{emptyListMessage}}}\n{{/isEmpty}}\n{{^isEmpty}}\n{{#previousPage}}\n  <a href=\'{{urlPrefix}}?page={{previousPage}}\' data-page=\'{{previousPage}}\'>← Previous</a>\n{{/previousPage}}\n{{^previousPage}}\n  <span>← Previous</span>\n{{/previousPage}}\n{{#pages}}\n  {{#currentPage}}\n    <span>{{page}}</span>\n  {{/currentPage}}\n  {{^currentPage}}\n    <a href=\'{{urlPrefix}}?page={{page}}\' data-page=\'{{page}}\'>{{page}}</a>\n  {{/currentPage}}\n{{/pages}}\n{{#nextPage}}\n  <a href=\'{{urlPrefix}}?page={{nextPage}}\' data-page=\'{{nextPage}}\'>Next →</a>\n{{/nextPage}}\n{{^nextPage}}\n  <span>Next →</span>\n{{/nextPage}}\n{{/isEmpty}}';

    Pagination.prototype.pagesJSON = function(currentPage, totalPages) {
      var firstPage, groupSize, lastPage, previousPage, _i, _results;
      groupSize = this.maxPages / 2;
      firstPage = currentPage < groupSize ? 1 : currentPage - groupSize;
      previousPage = firstPage + groupSize * 2 - 1;
      lastPage = previousPage >= totalPages ? totalPages : previousPage;
      return _.map((function() {
        _results = [];
        for (var _i = firstPage; firstPage <= lastPage ? _i <= lastPage : _i >= lastPage; firstPage <= lastPage ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this), function(page) {
        return {
          page: page,
          currentPage: function() {
            return currentPage === page;
          }
        };
      });
    };

    Pagination.prototype.paginationJSON = function(pagination) {
      return {
        isEmpty: pagination.total_pages === 0,
        emptyListMessage: this.emptyListMessage,
        currentPage: pagination.current_page,
        nextPage: pagination.next_page,
        previousPage: pagination.previous_page,
        urlPrefix: this.urlPrefix,
        pages: this.pagesJSON(pagination.current_page, pagination.total_pages)
      };
    };

    Pagination.prototype.render = function(data) {
      this.pagination = this.paginationJSON(data.pagination);
      return $(this.renderTo).html(Mustache.to_html(this.paginationTemplate, this.pagination));
    };

    Pagination.prototype.handlePaginationLinkClick = function(event) {
      event.preventDefault();
      return $(this.listSelector).trigger(this.eventName, {
        page: $(event.target).data('page')
      });
    };

    return Pagination;

  })(Utilities);

  window.Search = (function(_super) {

    __extends(Search, _super);

    function Search(globalOptions, options) {
      var _this = this;
      if (options == null) options = {};
      this.handleSearchFormSubmit = __bind(this.handleSearchFormSubmit, this);
      this.setOptions(globalOptions);
      this.setOptions(options);
      $(this.formSelector).submit(function(event) {
        return _this.handleSearchFormSubmit(event);
      });
    }

    Search.prototype.searchTerm = function() {
      var q;
      q = $(this.searchTextInputSelector).val();
      if (!q || (q === '')) {
        return null;
      } else {
        return q;
      }
    };

    Search.prototype.handleSearchFormSubmit = function(event) {
      event.preventDefault();
      return $(this.listSelector).trigger(this.eventName);
    };

    return Search;

  })(Utilities);

}).call(this);
