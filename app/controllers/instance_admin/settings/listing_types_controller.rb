class InstanceAdmin::Settings::ListingTypesController < InstanceAdmin::BaseController

  def create
    @listing_type = ListingType.new(params[:listing_type])
    @listing_type.instance = platform_context.instance
    if @listing_type.save
      flash[:success] = t('flash_messages.instance_admin.settings.listing_type_added')
      redirect_to instance_admin_settings_listings_path
    else
      flash[:error] = t('flash_messages.instance_admin.settings.listing_type_not_added')
      redirect_to instance_admin_settings_listings_path
    end
  end

  def destroy_modal
    @listing_type = platform_context.instance.listing_types.find(params[:id])

    if @listing_type.listings.count > 0
      @replacement_types = platform_context.instance.listing_types - [@listing_type]
      render :destroy_and_replace_modal, :layout => false
    else
      render :destroy_modal, :layout => false
    end
  end

  def destroy
    @listing_type = platform_context.instance.listing_types.find(params[:id])
    
    if @listing_type.listings.count > 0
      @replacement_type = platform_context.instance.listing_types.find(params[:replacement_type_id])
      @listing_type.listings.update_all(listing_type_id: @replacement_type.id)
    end

    @listing_type.destroy
    flash[:success] = t('flash_messages.instance_admin.settings.listing_type_deleted')
    redirect_to instance_admin_settings_listings_path
  end
end
