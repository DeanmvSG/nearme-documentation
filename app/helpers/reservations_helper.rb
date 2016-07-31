require 'money-rails'

module ReservationsHelper

  def location_query_string(location = @location)
    query = [location.state, location.city, location.country]
    query.reject! { |item| !item.present? || item == "Unknown" }
    query.join('%2C+')
  end

  def reservation_navigation_link(action)
    (link_to(content_tag(:span, action.titleize), self.send("#{action}_reservations_path"), :class => "upcoming-reservations btn btn-medium btn-gray#{action==params[:action] ? " active" : "-darker"}")).html_safe
  end

  def recurring_booking_reservations_navigation_link(recurring_booking, action)
    (link_to(content_tag(:span, action.titleize), self.send("#{action}_recurring_booking_path", recurring_booking), :class => "upcoming-reservations btn btn-medium btn-gray#{action==params[:action] ? " active" : "-darker"}")).html_safe
  end

  def upcoming_reservation_count
    @upcoming_reservation_count ||= current_user.orders.reservations.not_archived.count
  end

  def archived_reservation_count
    @archived_reservation_count ||= current_user.orders.reservations.archived.count
  end

  def secure_listing_url(listing, options = {})
    if Rails.env.production?
      options = options.reverse_merge(protocol: "https://")
    end

    listing_reservations_url(listing, options)
  end

  def booking_type_from_action(action)
    booking_type = I18n.t('reservations.upcoming')
    booking_type = I18n.t('reservations.archived') if action == 'archived'
    booking_type = I18n.t('recurring_bookings.active') if action == 'active'

    booking_type
  end

  def get_disabled_categories(listing)
    if listing.categories.any?
      (listing.categories.first.root.children - listing.categories).map(&:name)
    end
  end

  def last_search
    @last_search ||= JSON.parse(cookies[:last_search], symbolize_names: true) rescue {}
  end

  def get_categories_from_search
    if last_search[:category_ids]
      Category.where(id: last_search[:category_ids]).pluck(:name)
    else
      []
    end
  end


  def current_user_open_all_reservations_count
    current_user_open_host_reservations_count + current_user_open_user_reservations_count
  end

  def current_user_open_host_reservations_count_formatted
    reservations_count_formatted(current_user_open_host_reservations_count)
  end

  def current_user_open_host_reservations_count
    return 0 if current_user.default_company.blank?

    current_user.default_company.orders.active.unconfirmed.count
  end

  def current_user_open_user_reservations_count
    current_user.orders.unconfirmed.not_archived.count
  end

  def current_user_orders_count_formatted
    reservations_count_formatted(current_user.orders.not_archived.count)
  end

  def current_user_open_all_reservations_count_formatted
    reservations_count_formatted(current_user_open_all_reservations_count)
  end

  private

    def reservations_count_formatted(count)
      if count > 0
        "<span class='count'>#{count}</span>".html_safe
      end
    end

end
