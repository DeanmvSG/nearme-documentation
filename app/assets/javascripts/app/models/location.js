define(['backbone'], function(Backbone) {
  var LocationModel = Backbone.Model.extend({
    initialize: function(attributes) {},

    url: function() {
      var base = '/v1/locations';
      if (this.isNew()) {
        return base;
      }
      return base + (base.charAt(base.length - 1) == '/' ? '' : '/') + this.id;
    }

  });
  return LocationModel;
});

