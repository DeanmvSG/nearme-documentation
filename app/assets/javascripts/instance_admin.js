//= require jquery
//= require jquery_ujs
//= require ./vendor/jquery-ui-1.9.2.custom.min
//= require ./vendor/jQueryRotate
//= require ./instance_admin/bootstrap
//= require ./instance_admin/bootstrap-select
//= require ./vendor/modernizr
//= require ./vendor/Chart
//= require components/chart_wrapper
//= require bootstrap-switch
//= require components/photo
//= require components/ckfile
//= require jquery-fileupload/basic
//= require components/fileupload
//= require components/modal
//= require jcrop
//= require sections/search_instance_admin
//= require javascript_module
//= require ./instance_admin/searchable_admin_resource
//= require_tree ./instance_admin/sections
//= require jquery_nested_form
//= require ./vendor/urlify
//= require ./vendor/icui
//= require ./vendor/strftime
//= require ./blog/admin/blog_posts_form
//= require lib/timeago.jquery
//= require ckeditor/basepath
//= require ckeditor/init
//= require lib/timeago.jquery
//= require ./instance_admin/jquery.jstree
//= require components/ace_editor_textarea_binding
//= require sections/support
//= require sections/support/attachment_form
//= require sections/support/ticket_message_controller
//= require ./instance_admin/script
//= require chosen-jquery

//= require instance_admin/jquery-ui-datepicker
//= require instance_admin/sections/rating_systems
//= require instance_admin/sections/reviews

//= require instance_admin/sections/approval_requests

//= require instance_admin/sections/wish_lists
//= require instance_admin/sections/users
//= require instance_admin/sections/documents_upload

//= require instance_admin/data_tables/jquery.dataTables.min
//= require instance_admin/data_tables/dataTables.bootstrap
//= require instance_admin/sections/partners
//= require instance_admin/bootstrap-colorpicker.js

$(function() {
  Fileupload.initialize();
})

$('[rel=tooltip]').tooltip();

$('select.chosen').chosen();

// Graceful degradation for missing inline_labels
// Make the original label visible
$('.control-group.boolean .controls label.checkbox').each(function() {
  try {
    var text = $(this).html();
    if(text.match(/^\s*<[^<>]+>\s*$/)) {
      $(this).parents('.control-group.boolean').find('label.boolean.control-label').show();
    }
  } catch(e) {
    // Avoid graceful degradation code from impacting page
    // errors, if present are not treated
  }
});



