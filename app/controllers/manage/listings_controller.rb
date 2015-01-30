class Manage::ListingsController < Manage::BaseController
  before_filter :find_listing, :except => [:index, :new, :create]
  before_filter :find_transactable_type, except: [:index]
  before_filter :find_location
  before_filter :disable_unchecked_prices, :only => :update

  def index
    redirect_to new_manage_location_listing_path(@location)
  end

  def new
    @listing = @location.listings.build(:transactable_type => @transactable_type)
    @listing.availability_template_id = AvailabilityRule.default_template.id
    build_approval_request_for_object(@listing) unless @listing.is_trusted?
  end

  def create
    @listing = @location.listings.build(listing_params)
    build_approval_request_for_object(@listing) unless @listing.is_trusted?
    if @listing.save
      flash[:success] = t('flash_messages.manage.listings.desk_added', bookable_noun: @transactable_type.bookable_noun)
      event_tracker.created_a_listing(@listing, { via: 'dashboard' })
      event_tracker.updated_profile_information(current_user)
      redirect_to manage_locations_path
    else
      @photos = @listing.photos
      render :new
    end
  end

  def show
    redirect_to edit_manage_location_listing_path(@location, @listing)
  end

  def edit
    @photos = @listing.photos
    build_approval_request_for_object(@listing) unless @listing.is_trusted?
    event_tracker.track_event_within_email(current_user, request) if params[:track_email_event]
  end

  def update
    @listing.assign_attributes(listing_params)
    build_approval_request_for_object(@listing) unless @listing.is_trusted?
    respond_to do |format|
      format.html {
        if @listing.save
          flash[:success] = t('flash_messages.manage.listings.listing_updated')
          redirect_to manage_locations_path
        else
          @photos = @listing.photos
          render :edit
        end
      }
      format.json {
        if @listing.save
          render :json => { :success => true }
        else
          render :json => { :errors => @listing.errors.full_messages }, :status => 422
        end
      }
    end
  end

  def enable
    if @listing.enable!
      render :json => { :success => true }
    else
      render :json => { :errors => @listing.errors.full_messages }, :status => 422
    end
  end

  def disable
    if @listing.disable!
      render :json => { :success => true }
    else
      render :json => { :errors => @listing.errors.full_messages }, :status => 422
    end
  end

  def destroy
    @listing.reservations.each do |r|
      r.perform_expiry!
    end
    @listing.destroy
    event_tracker.updated_profile_information(current_user)
    event_tracker.deleted_a_listing(@listing)
    flash[:deleted] = t('flash_messages.manage.listings.listing_deleted')
    redirect_to manage_locations_path
  end

  private

  def find_location
    begin
      @location = if @listing
                    @listing.location
                  else
                    locations_scope.find(params[:location_id])
                  end
    rescue ActiveRecord::RecordNotFound
      raise Location::NotFound
    end
  end

  def find_listing
    begin
      @listing = Transactable.where(location_id: locations_scope.pluck(:id)).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      raise Transactable::NotFound
    end
  end

  def disable_unchecked_prices
    Transactable::PRICE_TYPES.each do |price|
      if params[:listing]["#{price}_price"].blank?
        @listing.send("#{price}_price=", nil) if @listing.respond_to?("#{price}_price_cents=")
      end
    end
  end

  def find_transactable_type
    @transactable_type = @listing.try(:persisted?) ? @listing.transactable_type : TransactableType.find(params[:transactable_type_id])
  end

  def listing_params
    params.require(:listing).permit(secured_params.transactable(@transactable_type))
  end
end
