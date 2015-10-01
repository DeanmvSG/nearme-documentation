class OnboardingController < ApplicationController

  include Wicked::Wizard

  before_filter :redirect_if_completed

  steps :location, :integrations, :followings, :finish

  def show
    @user = current_user
    case step
    when :location
      @address = @user.current_address || @user.build_current_address
    when :integrations
      cookies[:redirect_after_callback_to] = {value: view_context.wizard_path(step), expires: 10.minutes.from_now}
      @supported_providers = Authentication.available_providers
    when :followings
      @topics = Topic.featured.take(4)

      friends_projects = Project.where(creator_id: @user.social_friends_ids).take(4)
      featured_projects = Project.featured.take(4 - friends_projects.count)
      @projects = friends_projects + featured_projects

      friends = User.where(id: @user.social_friends_ids).take(4)
      nearby = User.near([current_user.current_address.latitude, current_user.current_address.longitude], 100).take(4 - friends.count)
      featured = User.featured.without(@user).includes(:current_address, :instance_profile_type).take(4 - friends.count - nearby.count)
      @people = friends + nearby + featured
    when :finish
      @custom_attributes = @user.instance_profile_type.custom_attributes.includes(:target).where(public: true).all
    end
    render_wizard
  end

  def update
    @user = current_user

    case step
    when :location
      @address = @user.current_address || @user.build_current_address
      @address.update_attributes(address_params)
      render_wizard @address
    when :integrations
      render_wizard @user
    when :followings
      @user.feed_followed_users << User.where(id: followed_params[:people]) if followed_params[:people]
      @user.feed_followed_projects << Project.where(id: followed_params[:projects]) if followed_params[:projects]
      @user.feed_followed_topics << Topic.where(id: followed_params[:topics]) if followed_params[:topics]
      render_wizard @user
    when :finish
      @user.update_attributes(user_params)
      render_wizard @user
    else
      raise NotImplementedError
    end
  end

  def finish_wizard_path
    current_user.update_attribute(:onboarding_completed, true)
    root_path
  end

  private

    def user_params
      params.require(:user).permit(secured_params.user).tap do |whitelisted|
        whitelisted[:properties] = params[:user][:properties] if params[:user][:properties]
      end
    end

    def address_params
      params.require(:address).permit(secured_params.address)
    end

    def followed_params
      params.require(:followed).permit(people: [], projects: [], topics: [])
    end

    def redirect_if_completed
      redirect_to root_path if current_user.onboarding_completed
    end

end
