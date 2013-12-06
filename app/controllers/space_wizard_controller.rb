class SpaceWizardController < ApplicationController

  before_filter :redirect_to_dashboard_if_user_has_listings, :only => [:new, :list]
  before_filter :find_user, :except => [:new]
  before_filter :find_company, :except => [:new, :submit_listing]
  before_filter :find_location, :except => [:new, :submit_listing]
  before_filter :find_listing, :except => [:new, :submit_listing]
  before_filter :find_user_country, :only => [:list, :submit_listing]
  before_filter :sanitize_price_parameters, :only => [:submit_listing]

  def new
    flash.keep(:warning)
    event_tracker.clicked_list_your_bookable({source: request.referer ? URI(request.referer).path : "direct"})
    if current_user
      redirect_to space_wizard_list_url
    else
      redirect_to new_user_registration_url(:wizard => 'space', :return_to => space_wizard_list_path)
    end
  end

  def list
    @company ||= @user.companies.build
    @location ||= @company.locations.build
    @location.name_required = true
    @listing ||= @location.listings.build
    @photos = @user.photos.where("content_type = 'Listing' AND content_id IS NOT NULL") || nil
    event_tracker.viewed_list_your_bookable
    event_tracker.track_event_within_email(current_user, request) if params[:track_email_event]
  end

  def submit_listing
    @user.phone_required = true
    params[:user][:companies_attributes]["0"][:instance_id] = platform_context.instance.id.to_s
    params[:user][:companies_attributes]["0"][:creator_id] = current_user.id.to_s
    params[:user][:companies_attributes]["0"][:partner_id] = platform_context.partner.try(:id).to_s
    params[:user][:companies_attributes]["0"][:name] = current_user.name if platform_context.instance.skip_company? && params[:user][:companies_attributes]["0"][:name].blank?

    set_listing_draft_timestamp(params[:save_as_draft] ? Time.zone.now : nil)
    @user.attributes = params[:user]
    @user.companies.first.try(:locations).try(:first).try {|l| l.name_required = true}
    if params[:save_as_draft]
      @user.valid? # Send .valid? message to object to trigger any validation callbacks
      @user.save(:validate => false)
      track_saved_draft_event
      PostActionMailer.enqueue_later(24.hours).list_draft(platform_context, @user)
      flash[:success] = t('flash_messages.space_wizard.draft_saved')
      redirect_to :list
    elsif @user.save
      track_new_space_event
      PostActionMailer.enqueue.list(platform_context, @user)
      flash[:success] = t('flash_messages.space_wizard.space_listed', bookable_noun: platform_context.decorate.bookable_noun)
      redirect_to manage_locations_path
    else
      @photos = @user.first_listing ? @user.first_listing.photos : nil
      flash.now[:error] = t('flash_messages.space_wizard.complete_fields')
      render :list
    end
  end

  def destroy_photo
    @photo = Photo.find(params[:id])
    if is_photo_admin?(@photo, current_user) && @photo.destroy
      render :text => { success: true, id: @photo.id }, :content_type => 'text/plain'
    else
      render :text => { :errors => @photo.errors.full_messages }, :status => 422, :content_type => 'text/plain'
    end
  end

  private

  def is_photo_admin?(photo, user)
    return true if photo.creator == user                         # if the user created the photo
    return true if photo.content.try('administrator') == user    # if the user is an admin of the photos content
    return true if @company.listings.include?(photo.content)     # if the photo content is a listing and belongs to company
  end

  def find_user
    @user = current_user
    redirect_to new_space_wizard_url unless @user
  end

  def find_company
    @company = current_user.companies.first if current_user.companies.any?
  end

  def find_location
    @location = @company.locations.first if @company && @company.locations.any?
  end

  def find_listing
    @listing = @location.listings.first if @location && @location.listings.any?
  end

  def redirect_to_dashboard_if_user_has_listings
    redirect_to manage_locations_path if current_user && current_user.listings.active.any?
  end

  def track_saved_draft_event
    event_tracker.saved_a_draft
  end

  def track_new_space_event
    @location = @user.locations.first
    @listing = @user.listings.first
    event_tracker.created_a_location(@location , { via: 'wizard' })
    event_tracker.created_a_listing(@listing, { via: 'wizard' })
    event_tracker.updated_profile_information(@user)
  end

  def set_listing_draft_timestamp(timestamp)
    begin
      params[:user][:companies_attributes]["0"][:locations_attributes]["0"][:listings_attributes]["0"][:draft] = timestamp
    rescue
      nil
    end
  end

  def find_user_country
    @country = if params[:user] && params[:user][:country_name]
      params[:user][:country_name]
    elsif @user.country_name.present?
      @user.country_name
    elsif request.location
      request.location.country
    end
  end

  def sanitize_price_parameters
    begin
      params[:user][:companies_attributes]["0"][:locations_attributes]["0"][:listings_attributes]["0"].select { |k, v| k.include?('_price') }.each do |k, v|
        params[:user][:companies_attributes]["0"][:locations_attributes]["0"][:listings_attributes]["0"][k] = v.to_f unless v.blank?
      end
    rescue
      # no need to do anything
    end
  end

end
