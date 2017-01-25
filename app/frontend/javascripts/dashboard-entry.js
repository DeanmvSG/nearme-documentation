'use strict';

import NM from 'nm';

require('expose?jQuery|expose?$!jquery');
require('jquery-ujs/src/rails');
require('jquery-ui/ui/widget');
require('bootstrap-sass/assets/javascripts/bootstrap');
require('../vendor/cocoon');


NM.on('ready', ()=>{
  require('initializers/shared/timeago.initializer');
  require('initializers/shared/ckeditor.initializer');
  require('initializers/shared/colorpicker.initializer');
  require('initializers/shared/payment_method_selector.initializer');

  require('initializers/dashboard/address.initializer');
  require('initializers/dashboard/attachment_input.initializer');
  require('initializers/dashboard/availability_rules.initializer');
  require('initializers/dashboard/booking_type.initializer');
  require('initializers/dashboard/category_autocomplete_input.initializer');
  require('initializers/dashboard/category_tree_input.initializer');
  require('initializers/dashboard/click_to_call.initializer');
  require('initializers/dashboard/collaborators.initializer');
  require('initializers/dashboard/complete_reservation.initializer');
  require('initializers/dashboard/condition_field.initializer');
  require('initializers/dashboard/datepickers.initializer');
  require('initializers/dashboard/dialog.initializer');
  require('initializers/dashboard/dimension_templates.initializer');
  require('initializers/dashboard/document_requirements.initializer');
  require('initializers/dashboard/draft_validation.initializer');
  require('initializers/dashboard/edit_user.initializer');
  require('initializers/dashboard/edit_user_form.initializer');
  require('initializers/dashboard/external_links.initializer');
  require('initializers/dashboard/flash_message.initializer');
  require('initializers/dashboard/forms.initializer');
  require('initializers/dashboard/hints.initializer');
  require('initializers/dashboard/image_input.initializer');
  require('initializers/dashboard/limiter.initializer');
  require('initializers/dashboard/linechart.initializer');
  require('initializers/dashboard/location_fields.initializer');
  require('initializers/dashboard/messages.initializer');
  require('initializers/dashboard/navigation.initializer');
  require('initializers/dashboard/order_items.initializer');
  require('initializers/dashboard/orders.initializer');
  require('initializers/dashboard/panel_tabs.initializer');
  require('initializers/dashboard/payment_modal.initializer');
  require('initializers/dashboard/phone_numbers.initializer');
  require('initializers/dashboard/photo_manipulator.initializer');
  require('initializers/dashboard/popup.initializer');
  require('initializers/dashboard/price_fields.initializer');
  require('initializers/dashboard/reviews.initializer');
  require('initializers/dashboard/saved_searches.initializer');
  require('initializers/dashboard/schedule.initializer');
  require('initializers/dashboard/shipping_profiles.initializer');
  require('initializers/dashboard/stripe.initializer');
  require('initializers/dashboard/sync_enabled_fields.initializer');
  require('initializers/dashboard/tags.initializer');
  require('initializers/dashboard/ticket_message.initializer');
  require('initializers/dashboard/white_label.initializer');
});
