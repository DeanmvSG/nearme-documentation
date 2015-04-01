class InstanceAdmin::ShippingOptions::ShippingProfilesController < InstanceAdmin::ShippingOptions::BaseController

  before_filter :set_breadcrumbs

  before_filter :get_company

  def index
    @shipping_categories = Spree::ShippingCategory.system_profiles
  end

  def new
    @shipping_category_form = ShippingCategoryForm.new(Spree::ShippingCategory.new, @company)
    @shipping_category_form.assign_all_attributes
    render :partial => 'dashboard/shipping_categories/shipping_category_form', :locals => { :form_url => instance_admin_shipping_options_shipping_profiles_path, :form_method => :post }
  end

  def create
    @shipping_category = @company.shipping_categories.build
    @shipping_category.user_id = current_user.id
    @shipping_category_form = ShippingCategoryForm.new(@shipping_category, @company, is_system_profile: true)
    if @shipping_category_form.submit(shipping_category_form_params)
      render :partial => 'dashboard/shipping_categories/shipping_category_form', :locals => { :form_url => instance_admin_shipping_options_shipping_profiles_path, :form_method => :post, :is_success => true }
    else
      render :partial => 'dashboard/shipping_categories/shipping_category_form', :locals => { :form_url => instance_admin_shipping_options_shipping_profiles_path, :form_method => :post }
    end
  end

  def edit
    shipping_category = @company.shipping_categories.system_profiles.find(params[:id])
    @shipping_category_form = ShippingCategoryForm.new(shipping_category, @company)
    @shipping_category_form.assign_all_attributes
    render :partial => 'dashboard/shipping_categories/shipping_category_form', :locals => { :form_url => instance_admin_shipping_options_shipping_profile_path(shipping_category), :form_method => :put }
  end

  def update
    @shipping_category = @company.shipping_categories.system_profiles.find(params[:id])
    @shipping_category_form = ShippingCategoryForm.new(@shipping_category, @company, is_system_profile: true)
    if @shipping_category_form.submit(shipping_category_form_params)
      render :partial => 'dashboard/shipping_categories/shipping_category_form', :locals => { :form_url => instance_admin_shipping_options_shipping_profiles_path, :form_method => :post, :is_success => true }
    else
      render :partial => 'dashboard/shipping_categories/shipping_category_form', :locals => { :form_url => instance_admin_shipping_options_shipping_profiles_path, :form_method => :post }
    end
  end

  def destroy
    @shipping_category = Spree::ShippingCategory.system_profiles.find(params[:id])
    @shipping_category.destroy

    redirect_to instance_admin_shipping_options_shipping_profiles_path
  end

  def get_shipping_categories_list
    shipping_categories = Spree::ShippingCategory.system_profiles

    render partial: "categories_list", locals: { shipping_categories: shipping_categories }
  end

  def disable_category
    shipping_category = Spree::ShippingCategory.system_profiles.find(params[:id])
    shipping_category.update_attributes(is_system_category_enabled: false)

    redirect_to instance_admin_shipping_options_shipping_profiles_path
  end

  def enable_category
    shipping_category = Spree::ShippingCategory.system_profiles.find(params[:id])
    shipping_category.update_attributes(is_system_category_enabled: true)

    redirect_to instance_admin_shipping_options_shipping_profiles_path
  end

  private

  def get_company
    @company = current_user.companies.first

    if @company.blank?
      flash[:error] = t('instance_admin.shipping_profiles.you_must_create_company')
      redirect_to '/'
    end
  end

  def set_breadcrumbs
    @breadcrumbs_title = 'Shipping Profiles'
  end

  def shipping_category_form_params
    params.require(:shipping_category_form).permit(secured_params.shipping_category_form)
  end

end

