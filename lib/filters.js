// Generated by CoffeeScript 1.4.0
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

window.Filters = (function(_super) {

  __extends(Filters, _super);

  function Filters(options, livelist) {
    this.handleAdvancedOptionsClick = __bind(this.handleAdvancedOptionsClick, this);

    var _this = this;
    this.livelist = livelist;
    this.filters = options.presets ? _.keys(options.presets) : [];
    this.initializeCookies();
    this.setOptions(options);
    $('input.filter_option', this.renderTo).live('change', function() {
      return $(_this.livelist.listSelector).trigger(_this.livelist.eventName);
    });
    $(this.advancedOptionsToggleSelector).click(this.handleAdvancedOptionsClick);
  }

  Filters.prototype.initializeCookies = function() {
    if (jQuery.cookie && this.useCookies && this.cookieName) {
      return this.cookieName = 'livelist_filter_presets';
    }
  };

  Filters.prototype.getPresets = function() {
    var cookie;
    if (jQuery.cookie && this.useCookies) {
      cookie = jQuery.cookie(this.cookieName);
    }
    if (this.useCookies && cookie) {
      return JSON.parse(cookie);
    } else {
      return this.presets;
    }
  };

  Filters.prototype.setPresets = function(presets) {
    var filters;
    filters = {};
    if (jQuery.isEmptyObject(presets)) {
      filters = this.selections();
      if (jQuery.cookie) {
        this.setCookie(filters);
      }
    } else {
      filters = presets;
    }
    return filters;
  };

  Filters.prototype.setCookie = function(params_filters) {
    if (!jQuery.isEmptyObject(params_filters)) {
      return jQuery.cookie(this.cookieName, JSON.stringify(params_filters));
    }
  };

  Filters.prototype.template = '{{#filters}}\n<div class=\'filter\'>\n  <h3>\n    {{name}}\n  </h3>\n  <ul id=\'{{filter_slug}}_filter_options\'>\n    {{#options}}\n    <label>\n      <li>\n        <input {{#selected}}checked=\'checked\'{{/selected}}\n               class=\'left filter_option\'\n               id=\'filter_{{slug}}\'\n               name=\'filters[]\'\n               type=\'checkbox\'\n               value=\'{{value}}\' />\n        <div class=\'left filter_name\'>{{name}}</div>\n        <div class=\'right filter_count\'>{{count}}</div>\n        <div class=\'clear\'></div>\n      </li>\n    </label>\n    {{/options}}\n  </ul>\n</div>\n{{/filters}}';

  Filters.prototype.selections = function() {
    var filters,
      _this = this;
    filters = {};
    _.each(this.filters, function(filter) {
      return filters[filter] = _.pluck($("#" + filter + "_filter_options input.filter_option:checked"), 'value');
    });
    return filters;
  };

  Filters.prototype.noFiltersSelected = function(data) {
    return _.all(data.filters, function(filter) {
      return _.all(filter.options, function(option) {
        return !option.selected;
      });
    });
  };

  Filters.prototype.sortOptions = function(filters) {
    return _.map(filters, function(filter) {
      filter.options = _.sortBy(filter.options, function(option) {
        return option.name;
      });
      return filter;
    });
  };

  Filters.prototype.sort = function(filters) {
    return _.sortBy(filters, function(filter) {
      return filter.name;
    });
  };

  Filters.prototype.render = function(data) {
    var filtersHTML;
    this.filters = _.pluck(data.filters, 'filter_slug');
    this.sort(data.filters);
    this.sortOptions(data.filters);
    filtersHTML = Mustache.to_html(this.template, data);
    $(this.renderTo).html(filtersHTML);
    if (this.noFiltersSelected(data) && data[this.livelist.resourceName].length > 0) {
      return $('input[type="checkbox"]', this.renderTo).attr('checked', 'checked');
    }
  };

  Filters.prototype.handleAdvancedOptionsClick = function(event) {
    event.preventDefault();
    return $(this.renderTo).slideToggle();
  };

  return Filters;

})(Utilities);