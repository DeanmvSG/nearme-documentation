var InstanceAdminApprovalRequestsController,
  JavascriptModule,
  SearchableAdminResource,
  extend = function(child, parent) {
    for (var key in parent) {
      if (hasProp.call(parent, key))
        child[key] = parent[key];
    }
    function ctor() {
      this.constructor = child;
    }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.__super__ = parent.prototype;
    return child;
  },
  hasProp = {}.hasOwnProperty;

JavascriptModule = require('../../lib/javascript_module');

SearchableAdminResource = require('../searchable_admin_resource');

InstanceAdminApprovalRequestsController = function(superClass) {
  extend(InstanceAdminApprovalRequestsController, superClass);

  InstanceAdminApprovalRequestsController.include(SearchableAdminResource);

  function InstanceAdminApprovalRequestsController(container) {
    this.container = container;
    this.commonBindEvents();
  }

  return InstanceAdminApprovalRequestsController;
}(JavascriptModule);

module.exports = InstanceAdminApprovalRequestsController;
