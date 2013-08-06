class Manage::ListingsController < Manage::BaseController

  before_filter :find_listing, :except => [:index, :new, :create]
  before_filter :find_location

  def index
    redirect_to new_manage_location_listing_path(@location)
  end

  def new
    @listing = @location.listings.build(
      :daily_price_cents => 50_00,
      :availability_template_id => AvailabilityRule.default_template.id
    )
  end

  def create
    @listing = @location.listings.build(params[:listing])
    @listing.photo_required = true

    if params[:uploaded_photos]
      @listing.photos << current_user.photos.find(params[:uploaded_photos])
    end

    if @listing.save
      flash[:success] = "Great, your new Desk/Room has been added!"
      redirect_to manage_locations_path
    else
      render :new
    end
  end

  def show
    redirect_to edit_manage_location_listing_path(@location, @listing)
  end

  def edit
  end

  def update
    @listing.assign_attributes(params[:listing])
    @listing.photo_required = true

    if @listing.save
      flash[:success] = "Great, your listing's details have been updated."
      redirect_to manage_locations_path
    else
      render :edit
    end
  end

  def destroy
    @listing.destroy

    flash[:deleted] = "That listing has been deleted."
    redirect_to manage_locations_path
  end

  private

  def find_location
    @location = if @listing
                  @listing.location
                else
                  current_user.locations.find(params[:location_id])
                end
  end

  def find_listing
    @listing = current_user.listings.find(params[:id])
  end

end
