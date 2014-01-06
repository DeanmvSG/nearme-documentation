class AuthenticationsController < ApplicationController

  skip_before_filter :redirect_to_set_password_unless_unnecessary, :only => [:create]

  def create
    @omniauth = request.env["omniauth.auth"]
    @oauth = Auth::Omni.new(@omniauth)
    # if we are logged in as X, and we try to connect authentication that belongs to Y, we raise this error to prevent re-logging. 
    if @oauth.already_connected?(current_user)
      already_connected_to_other_user
    # Usual scenario - user already used social provider to log in to our system, everything in db is already set up
    elsif !current_user && @oauth.authentication
      signed_in_successfully
    # Email is already taken - don't allow to steal account
    elsif @oauth.email_taken_by_other_user?(current_user)
      user_changed_email_and_someone_else_picked_it
    # There is no authentication in our system, but user is logged in - we just add authentications to his account
    elsif current_user
      new_authentication_for_existing_user
    # There is no authentication in our system, and the user is not logged in. Hence, we create a new user and then new authentication
    else
      if @oauth.create_user(cookies[:google_analytics_id])
        # User and authentication created successfully. User is now logged in
        new_user_created_successfully
      else
        # something went wrong while creating a user - most likely provider did not return email. We will ask user to provide one via normal form.
        failed_to_create_new_user
      end
    end
  end

  def destroy
    @authentication = current_user.authentications.find(params[:id])
    if @authentication.can_be_deleted?
      @authentication.destroy
      log_disconnect_social_provider
      flash[:deleted] = t('flash_messages.authentications.disconnected', 
        provider_name: @authentication.provider.titleize)
    else
      flash[:warning] = t('flash_messages.authentications.unable_to_disconnect', 
        provider_name: @authentication.provider.titleize)
    end
    redirect_to edit_user_registration_url
  end

  # Clear any omniauth data stored in session
  def clear
    session[:omniauth] = nil
    head :ok
  end

  def failure
    flash[:error] = t('flash_messages.authentications.couldnt_authenticate', reason: params[:message].presence || "Unknown")
    redirect_to new_user_session_url
  end

  private

  def wizard_id
    oparams = request.env['omniauth.params']
    oparams && oparams['wizard']
  end

  def use_flash_messages?
    wizard_id.blank?
  end

  def after_sign_in_path_for(resource)
    if wizard_id
      wizard(wizard_id).url
    else
      super
    end
  end

  def already_connected_to_other_user
    flash[:error] = t('flash_messages.authentications.already_connected_to_other_user') if use_flash_messages?
    redirect_to edit_user_registration_path
  end

  def signed_in_successfully
    flash[:success] = t('flash_messages.authentications.signed_in_successfully') if use_flash_messages?
    @oauth.remember_user!
    @oauth.update_token_info
    update_analytics_google_id(@oauth.authenticated_user)
    log_logged_in
    sign_in_and_redirect(:user, @oauth.authenticated_user)
  end

  def user_changed_email_and_someone_else_picked_it
    flash[:error] = t('omniauth.email_taken_html', provider: @omniauth['provider'].titleize,
      sign_in_link: view_context.link_to('sign in', new_user_session_path),
      recovery_link: view_context.link_to('recover your password', new_user_password_path))
    redirect_to root_path
  end

  def new_authentication_for_existing_user
    @oauth.create_authentication!(current_user)
    @oauth.apply_avatar_if_empty
    log_connect_social_provider
    flash[:success] = t('flash_messages.authentications.authentication_successful')
    redirect_to edit_user_registration_url
  end

  def new_user_created_successfully
    @oauth.authenticated_user
    log_sign_up
    log_connect_social_provider
    @oauth.remember_user!
    @oauth.update_token_info
    flash[:success] = t('flash_messages.authentications.signed_in_successfully') if use_flash_messages?
    sign_in_and_redirect(:user, @oauth.authenticated_user)
  end

  def failed_to_create_new_user
    session[:omniauth] = @omniauth.except('extra')
    redirect_to new_user_registration_url(:wizard => wizard_id)
  end

  def log_sign_up
    analytics_apply_user(@oauth.authenticated_user)
    event_tracker.signed_up(@oauth.authenticated_user, { signed_up_via: 'other', provider: @oauth.provider })
  end

  def log_logged_in
    analytics_apply_user(@oauth.authenticated_user)
    event_tracker.logged_in(@oauth.authenticated_user, { provider: @oauth.provider } )
  end

  def log_connect_social_provider
    event_tracker.connected_social_provider(@oauth.authenticated_user, { provider: @oauth.provider } )
  end

  def log_disconnect_social_provider
    event_tracker.disconnected_social_provider(@authentication.user, { provider: @authentication.provider } )
  end

end
