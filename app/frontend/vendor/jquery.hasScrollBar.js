/* global jQuery */
(function($) {
    'use strict';
    $.fn.hasScrollBar = function() {
        return this.get(0).scrollHeight > this.height();
    };
})(jQuery);