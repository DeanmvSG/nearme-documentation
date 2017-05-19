var BootstrapSwitchInitializer;

require('bootstrap-switch/src/coffee/bootstrap-switch');

BootstrapSwitchInitializer = function() {
  function BootstrapSwitchInitializer(el) {
    this.el = $(el);
    this.bindEvents();
    this.initialize();
  }

  BootstrapSwitchInitializer.prototype.bindEvents = function() {};

  BootstrapSwitchInitializer.prototype.initialize = function() {
    return this.el.bootstrapSwitch();
  };

  return BootstrapSwitchInitializer;
}();

module.exports = BootstrapSwitchInitializer;