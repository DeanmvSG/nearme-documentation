class @InstanceAdmin.ProductsController extends @JavascriptModule
  @include SearchableAdminResource
  @include SearchableAdminService

  constructor: (@container) ->
    @commonBindEvents()
    @serviceBindEvents()
