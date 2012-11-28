// Generated by CoffeeScript 1.4.0
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

window.LiveList = (function(_super) {

  __extends(LiveList, _super);

  function LiveList(options) {
    this.listSelector = options.list.renderTo;
    this.resourceName = options.global.resourceName;
    this.resourceNameSingular = options.global.resourceNameSingular;
    this.urlPrefix = options.global.urlPrefix || ("/" + this.resourceName);
    this.httpMethod = options.global.httpMethod || 'get';
    this.eventName = "livelist:" + this.resourceName;
    this.search = new Search(options.search, this);
    this.filters = new Filters(options.filters, this);
    this.pagination = new Pagination(options.pagination, this);
    this.list = new List(options.list, this);
  }

  return LiveList;

})(Utilities);