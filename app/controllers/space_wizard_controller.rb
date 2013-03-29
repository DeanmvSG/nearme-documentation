class SpaceWizardController < ApplicationController

  before_filter :find_user, :except => [:new]
  before_filter :find_company, :except => [:new]
  before_filter :find_location, :except => [:new]
  before_filter :find_listing, :except => [:new]
  before_filter :convert_price_params, only: [:submit_listing]

  def new
    flash.keep(:notice)
    if current_user
      redirect_to space_wizard_list_url
    else
      redirect_to new_user_registration_url(:wizard => 'space')
    end
  end

  def list
    @company ||= @user.companies.build
    @location ||= @company.locations.build
    @listing ||= @location.listings.build
  end

  def submit_listing
    @company ||= @user.companies.build
    @company.attributes = params[:company]

    if @company.save
      if params[:uploaded_photos]
        listing = @company.locations.first.listings.first
        listing.photos << current_user.photos.find(params[:uploaded_photos])
        listing.save!
      end
      redirect_to controlpanel_path, notice: 'Your space was listed! You can provide more details about your location and listing from this page.'
    else
      render :list
    end
  end


  def submit_photo
    @photo = Photo.new
    @photo.image = params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:photos_attributes]["0"][:image]
    @photo.content_type = 'Listing'
    @photo.creator_id = current_user.id
    if @photo.save
      render :json => {:id => @photo.id, :url => @photo.image_url(:thumb).to_s, :destroy_url => destroy_space_wizard_photo_path(:id => @photo.id) }
    else
      render :json => [{:error => @photo.errors.full_messages}], :status => 422
    end
  end

  def destroy_photo
    @photo = current_user.photos.find(params[:id])
    if @photo.destroy
      render json: { success: true, id: @photo.id }
    else
      render :json => { :errors => @photo.errors.full_messages }, :status => 422
    end
  end


  private

  def find_user
    @user = current_user

    unless @user
      redirect_to new_space_wizard_url
    end
  end

  def find_company
    if current_user.companies.any?
      @company = current_user.companies.first
    end
  end

  def find_location
    if @company && @company.locations.any?
      @location = @company.locations.first
    end
  end

  def find_listing
    if @location && @location.listings.any?
      @listing = @location.listings.first
    end
  end

  def convert_price_params
    # method to_f removes all special characters, like hyphen. However we do not want to convert nil to 0, that's why modifier.
    params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:daily_price] = params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:daily_price].to_f if params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:daily_price]
    params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:weekly_price] = params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:weekly_price].to_f if params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:weekly_price]
    params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:monthly_price] = params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:monthly_price].to_f if params[:company][:locations_attributes]["0"][:listings_attributes]["0"][:monthly_price]
  end

end
