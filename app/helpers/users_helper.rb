module UsersHelper
  def user_is_admin?
    current_user && current_user.admin?
  end

  def user_country_name_options
    if (allowed_countries = current_instance.allowed_countries_list).present?
      allowed_countries.map { |c| [c.name, c.name, {:'data-calling-code' => c.calling_code}] }.sort_by(&:first)
    else
      Country.all.map { |c| [c.name, c.name, {:'data-calling-code' => c.calling_code}] }.sort_by(&:first)
    end
  end

  def user_country_default(country)
    Country.find_by_name(country) ? country : current_instance.default_country
  end

  def admin_as_user?
    session[:admin_as_user].present? && current_user
  end

  def instance_admin_as_user?
    session[:instance_admin_as_user].present? && current_user
  end

  def original_admin_user
    @original_admin_user ||= User.find(session[:admin_as_user][:admin_user_id])
  end

  def original_instance_admin_user
    @original_instance_admin_user ||= User.find(session[:instance_admin_as_user][:admin_user_id])
  end

  def render_social_connection(user, authentication)
    return "" unless authentication
    icon = "ico-" + social_icon(authentication.provider)
    render('registrations/social_connection', {
      icon: icon,
      provider: authentication.provider,
      count: authentication.total_social_connections,
      link: user.social_url(authentication.provider),
      rel: nil
    })
  end

  def param_reviews_page_present?
    params[:reviews_page].present?
  end

  def active_tab?(tab)
    case tab
    when 'products'
      !param_reviews_page_present? && @products.count > 0
    when 'services'
      !param_reviews_page_present? && @listings.count > 0
    when 'reviews'
      param_reviews_page_present? || @company.nil?
    end
  end

  def user_filter_checked?(filter)
    params[:filters].try(:include?, filter.to_s)
  end

  def user_has_own_reviews?
    params[:option] == 'reviews_left_by_seller' || params[:option] == 'reviews_left_by_buyer'
  end

  private

  def social_icon(provider)
    provider == 'facebook' ? 'facebook-full' : provider.to_s
  end
end
