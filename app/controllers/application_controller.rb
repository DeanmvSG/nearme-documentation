class ApplicationController < ActionController::Base

  protect_from_forgery
  layout "new_layout"
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  before_filter :set_tabs

  #booking_request: {"listings"=>
      #{"0"=>{"id"=>"728",
             #"bookings"=>{"0"=>{"date"=>"2013-01-16", "quantity"=>"3"},
                          #"1"=>{"date"=>"2013-01-23", "quantity"=>"3"},
                          #"2"=>{"date"=>"2013-01-30", "quantity"=>"3"}}}}, "action"=>"review", "controller"=>"locations/reservations", "location_id"=>"733"}

  def store_bookings_request
    unless current_user
      session[:user_return_to] =  "/locations/#{params[:location_id]}"
      session[:user_bookings_request] = request.params[:listings]
    end
  end

  protected

  def bookings_request
    logger.info("bookings_request: #{session[:user_bookings_request]}")
    session[:user_bookings_request] || Array.new
  end

  def requested_dates
    if session[:user_reservations]
       dates = session[:user_reservations][:listings]["0"][:bookings].map { |index,booking| booking.fetch("date") }
    else
      Array.new
    end
  end

  def clear_requested_bookings
    session.delete(:user_bookings_request)
  end

  private

  def set_tabs
  end

  def stored_url_for(resource_or_scope)
    session[:user_return_to] || root_path
  end

  def after_sign_in_path_for(resource)
    stored_url_for(resource)
  end

  # Some generic information on wizard for use accross controllers
  WizardInfo = Struct.new(:id, :url)

  # Return an object with information for a given wizard
  def wizard(name)
    return name if WizardInfo === name

    case name.to_s
    when 'space'
      WizardInfo.new(name.to_s, new_space_wizard_url)
    end
  end
  helper_method :wizard

  def redirect_for_wizard(wizard_id_or_object)
    redirect_to wizard(wizard_id_or_object).url
  end

  def not_found
    render "public/404", :status => :not_found
  end

end
