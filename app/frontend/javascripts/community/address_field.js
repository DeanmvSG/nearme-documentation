/* global google */

/*
 * Wrapper for the address and geolocation fields.
 *
 * Provides an autocomplete on the address field, and sets the location geolocation
 * fields (lat, long, address, etc.) on the form.
 */
var AddressComponentParser,
  AddressField,
  SearchGeocoder,
  bind = function(fn, me) {
    return function() {
      return fn.apply(me, arguments);
    };
  };

SearchGeocoder = require('./search/geocoder');

AddressComponentParser = require('./address_component_parser');

AddressField = function() {
  function AddressField(input) {
    this.input = input;
    this.markerMoved = bind(this.markerMoved, this);
    this.inputWrapper = this.input.closest('[data-address-field]');
    this.autocomplete = new google.maps.places.Autocomplete(this.input[0], {});
    this.addressComponentParser = new AddressComponentParser(this.inputWrapper);
    google.maps.event.addListener(
      this.autocomplete,
      'place_changed',
      function(_this) {
        return function() {
          var place;
          place = SearchGeocoder.wrapResult(_this.autocomplete.getPlace());
          if (!place.isValid()) {
            place = null;
          }
          if (place) {
            return _this.pickSuggestion(place);
          }
        };
      }(this)
    );
    this.input.focus(
      function(_this) {
        return function() {
          return _this.picked_result = false;
        };
      }(this)
    );
    this.input.blur(
      function(_this) {
        return function() {
          var geocoder;
          geocoder = new SearchGeocoder();
          return setTimeout(
            function() {
              var deferred, first_item, query;
              if (!_this.picked_result) {
                if ($('.pac-container').find('.pac-item').length > 0 && _this.input.val() !== '') {
                  geocoder = new SearchGeocoder();
                  first_item = $('.pac-container').find('.pac-item').eq(0);
                  query = first_item.find('.pac-item-query').eq(0).text() + ', ' +
                    first_item.find('> span').eq(-1).text();
                  deferred = geocoder.geocodeAddress(query);
                  return deferred.done(function(resultset) {
                    var result;
                    result = SearchGeocoder.wrapResult(resultset.getBestResult().result);
                    _this.input.val(query);
                    return _this.pickSuggestion(result);
                  });
                } else {
                  _this.setLatLng(null, null);
                  _this.inputWrapper.find('[data-formatted-address]').val(null);
                  _this.inputWrapper.find('[data-local-geocoding]').val('1');
                  _this.input.parent().find('.address_components_input').remove();
                  if (_this._onLocate) {
                    return _this._onLocate(null, null);
                  }
                }
              }
            },
            200
          );
        };
      }(this)
    );
  }

  AddressField.prototype.markerMoved = function(lat, lng) {
    return setTimeout(
      function(_this) {
        return function() {
          var deferred, geocoder;
          geocoder = new SearchGeocoder();
          deferred = geocoder.reverseGeocodeLatLng(lat, lng);
          return deferred.done(function(resultset) {
            var result;
            result = SearchGeocoder.wrapResult(resultset.getBestResult().result);
            _this.input.val(result.formattedAddress());
            return _this.pickSuggestion(result);
          });
        };
      }(this),
      200
    );
  };

  AddressField.prototype.bump = function() {
    if (
      this.inputWrapper.find('[data-latitude]').val() &&
        this.inputWrapper.find('[data-longitude]').val()
    ) {
      return this.setLatLngWithCallback(
        this.inputWrapper.find('[data-latitude]').val(),
        this.inputWrapper.find('[data-longitude]').val()
      );
    }
  };

  AddressField.prototype.onLocate = function(callback) {
    return this._onLocate = callback;
  };

  AddressField.prototype.pickSuggestion = function(place) {
    this.picked_result = true;
    this.setLatLng(place.lat(), place.lng());
    this.inputWrapper.find('[data-formatted-address]').val(place.formattedAddress());
    this.inputWrapper.find('[data-local-geocoding]').val('1');
    this.addressComponentParser.buildAddressComponentsInputs(place);
    if (this._onLocate) {
      return this._onLocate(place.lat(), place.lng());
    }
  };

  /*
   * Used by map controllers to update the lat-lng by moving map marker.
   */
  AddressField.prototype.setLatLng = function(lat, lng) {
    this.inputWrapper.find('[data-latitude]').val(lat);
    return this.inputWrapper.find('[data-longitude]').val(lng);
  };

  AddressField.prototype.setLatLngWithCallback = function(lat, lng) {
    this.setLatLng(lat, lng);
    if (this._onLocate) {
      return this._onLocate(lat, lng);
    }
  };

  return AddressField;
}();

module.exports = AddressField;