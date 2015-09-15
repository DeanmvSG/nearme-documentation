class InstanceAdmin::Reports::ProductsController < InstanceAdmin::Reports::BaseController

  include ReportsProperties

  before_filter :set_breadcrumbs_title

  def index
    @product_search_form = InstanceAdmin::ProductSearchForm.new
    @product_search_form.validate(params)
    @products = SearchService.new(Spree::Product.order('created_at DESC')).search(@product_search_form.to_search_params).paginate(page: params[:page])
  end

  def download_report
    @product_search_form = InstanceAdmin::ProductSearchForm.new
    @product_search_form.validate(params)
    @products = SearchService.new(Spree::Product.order('created_at DESC')).search(@product_search_form.to_search_params).paginate(page: params[:page])
    @product_type = Spree::ProductType.find_by_id(params[:item_type_id])

    csv = export_data_to_csv_for_products(@products, @product_type)

    respond_to do |format|
      format.csv { send_data csv }
    end
  end

  def show
    append_to_breadcrumbs(t('instance_admin.general.product'))
    @product = Spree::Product.find(params[:id])
  end

  def set_breadcrumbs_title
    @breadcrumbs_title = BreadcrumbsList.new(
      { :title => t('instance_admin.general.reports') },
      { :title => t('instance_admin.general.products'), :url => instance_admin_reports_products_path }
    )
  end
end
