class RegistrationsController < Devise::RegistrationsController

  # NB: Devise calls User.new_with_session when building the new User resource.
  # We use this to apply any Provider based authentications to the user record.
  # This is trigged via Devise::RegistrationsController#build_resource

  # We extend the create action to clear out any stored Provider auth data used during
  # registration.
  before_filter :find_supported_providers, :only => [:edit, :update]

  def create
    super
    AfterSignupMailer.delay({:run_at => 60.minutes.from_now}).help_offer(@user)
    # Clear out temporarily stored Provider authentication data if present
    session[:omniauth] = nil unless @user.new_record?
    flash[:redirected_from_sign_up] = true
  end

  def edit
    super
  end

  def update
    if resource.update_with_password(params[resource_name])
      set_flash_message :notice, :updated
      sign_in(resource, :bypass => true)
      redirect_to :action => 'edit'
    else
      render :edit
    end
  end

  def destroy
    raise ActionController::RoutingError, "Feature disabled"
  end

  protected

  def is_navigational_format?
    # Wizards don't get flash messages
    if params[:wizard]
      false
    else
      super
    end
  end

  def after_sign_up_path_for(resource)
    # Wizards go back to the wizard after signup
    if params[:wizard]
      wizard(params[:wizard]).url
    else
      super
    end
  end

  def find_supported_providers
    @supported_providers = Authentication.available_providers
  end

end
