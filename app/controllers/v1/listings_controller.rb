class V1::ListingsController < V1::BaseController

  skip_before_filter :verify_authenticity_token, :only => [:create, :update, :destroy]

  # Endpoints that require authentication
  before_filter :require_authentication,         only: [:create, :update, :destroy, :connections, :inquiry, :reservation, :share]
  before_filter :find_listing,                   only: [:update, :destroy]
  before_filter :convert_price_params,           only: [:create, :update]
  before_filter :validate_search_params!,        only: :search
  before_filter :validate_query_params!,         only: :query
  before_filter :validate_reservation_params!,   only: :reservation
  before_filter :validate_availability_params!,  only: :availability
  before_filter :validate_inquiry_params!,       only: :inquiry

  # Default error handler
  rescue_from ActiveRecord::RecordNotFound, with: :listing_not_found

  def list
    @listings = current_user.company(params[:location_id]).listings.active.visible.select('id,name')
  end

  def create
    @listing = Transactable.new(:transactable_type_id => TransactableType.first.id)
    @listing.assign_attributes(listing_params)
    if @listing.save
      render :json => {:success => true, :id => @listing.id}
    else
      render :json => { :errors => @listing.errors.full_messages }, :status => 422
    end
  end

  def update
    if params[:listing][:photos_attributes] == nil
      params[:listing].delete :photos_attributes
    end
    @listing.assign_attributes(listing_params)

    if @listing.save
      render :json => @listing, :root => false, :serializer => ListingWebSerializer
    else
      render :json => { :errors => @listing.errors.full_messages }, :status => 422
    end
  end

  def destroy
    if @listing.destroy
      render json: { success: true, id: @listing.id }
    else
      render :json => { :errors => @listing.errors.full_messages }, :status => 422
    end
  end

  def show
    render :json => Transactable.active.find(params[:id]), root: 'listing'
  end

  def search
    params_object = Listing::Search::Params::Api.new(json_params.merge(user: current_user))
    search_params = params.merge({:midpoint => params_object.midpoint, :radius => params_object.radius, :available_dates => params_object.available_dates})
    listings = Listing::SearchFetcher.new(search_params).listings
    render :json => listings
  end

  def query
    search
  end

  # Create a new reservation
  def reservation
    listing     = Transactable.find(params[:id])
    reservation = listing.reserve!(current_user, @dates, @quantity)

    # Render the newly created reservation
    render :json => reservation
  end

  # Retrieve the reservation availability for a listing
  def availability
    listing = Transactable.find(params[:id])
    render :json => formatted_availability_for(listing, @dates)
  end

  def inquiry
    listing = Transactable.find(params[:id])
    @message = json_params["message"]

    inquiry = listing.inquiry_from!(current_user, message: @message)
    WorkflowStepJob.perform(WorkflowStep::InquiryWorkflow::Created, inquiry.id)

    head :no_content
  end

  def share
    users = validate_share_params!
    listing = Transactable.find(params[:id])
    message = json_params["query"]
    users.each do |user|
      WorkflowStepJob.perform(WorkflowStep::ListingWorkflow::Shared, listing.id, user["email"], user["name"], current_user.id, message)
    end

    head :no_content
  end

  def patrons
    listing = Transactable.find(params[:id])
    patrons = User.patron_of(listing)
    render json: formatted_patrons(listing, patrons)
  end

  # Return the user's connections associated with the listing
  def connections
    listing = Transactable.find(params[:id])
    users = current_user.followed_users.patron_of(listing)
    patrons = User.joins(:reservations).where(:reservations => { :transactable_id => listing.id }).where(:id => users.pluck('users.id')).uniq
    render json: formatted_patrons(listing, patrons)
  end

  ##
  ##
  protected

  # Formatted hash of patrons for a given listing
  def formatted_patrons(listing, patrons)
    {
      listing_id: listing.id,
      users: patrons.map { |p|
        {
          id: p.id,
          name: p.name,
          avatar: formatted_avatar(p)
        }
      }
    }
  end

  # Formatted hash of a User's avatar images
  def formatted_avatar(patron)

    return {} if patron.avatar.blank?
    {
        thumb_url:  "#{patron.avatar_url(:thumb)}",
        medium_url: "#{patron.avatar_url(:medium)}",
        large_url:  "#{patron.avatar_url(:large)}"
    }

  end


  def validate_search_params!
    raise DNM::MissingJSONData, "boundingbox" if json_params["boundingbox"].blank?
  end


  def validate_query_params!
    raise DNM::MissingJSONData, "query" if json_params["query"].blank?
  end


  # Validate the JSON POST for reserving a listing
  def validate_reservation_params!

    # Dates are required
    raise DNM::MissingJSONData, "dates" if json_params["dates"].blank?
    @dates = Array(json_params["dates"])
    begin
      @dates.map! { |d| Date.parse d }.sort!
    rescue
      raise DNM::InvalidJSONData, "dates"
    end

    # Dates cannot be in the past
    @dates.each { |date|
      raise DNM::InvalidJSONDate.new("dates") if date.past?
    }

    @email = json_params["email"]
    raise DNM::MissingJSONData, "email" if @email.blank?

    @quantity = json_params["quantity"]
    @assignees = json_params["assignees"]

    # Default for quantity
    if @quantity.blank?
      if @assignees.blank?
        @quantity = 1
      else
        @quantity = @assignees.length
      end
    end
  end

  def validate_availability_params!
    raise DNM::MissingJSONData, "dates" if json_params["dates"].blank?
    @dates = Array(json_params["dates"])
    @dates.map! { |d| Date.parse d }.sort!
  rescue
    raise DNM::InvalidJSONData, "dates"
  end

  def validate_inquiry_params!
    raise DNM::MissingJSONData, "message" if json_params["message"].blank?
  end

  def validate_share_params!
    users = json_params["to"]
    raise DNM::MissingJSONData, "to" if users.blank?
    users.each { |user|
      raise DNM::MissingJSONData, "name"  if user["name"].blank?
      raise DNM::MissingJSONData, "email" if user["email"].blank?
    }
  end

  def listing_not_found
    # Kinda wish we could return a 404 here...
    e = DNM::Error.new "Missing Listing"
    e.errors << { resource: "Listing",
                  field:    "id",
                  code:     "missing" }
    render json: e.to_hash, status: e.status
  end

  # Formatted listing availability record
  def formatted_availability_for(listing, dates)

    list = dates.map { |date|

      timestamp_start = date.beginning_of_day
      timestamp_end = timestamp_start.tomorrow - 1

      {
        start_at: timestamp_start,
        end_at: timestamp_end,
        available: listing.availability_for(date)
      }
    }

    {
        listing_id: listing.id,
        availability: list
    }
  end

  private
    def find_listing
      @listing = current_user.listings.find(params[:id])
    end

    def convert_price_params
      params[:listing][:daily_price] = params[:listing][:daily_price].to_f if params[:listing][:daily_price]
      params[:listing][:weekly_price] = params[:listing][:weekly_price].to_f if params[:listing][:weekly_price]
      params[:listing][:monthly_price] = params[:listing][:monthly_price].to_f if params[:listing][:monthly_price]
    end

    def listing_params
      params.require(:listing).permit(secured_params.transactable)
    end
end
