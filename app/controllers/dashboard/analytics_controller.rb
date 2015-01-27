class Dashboard::AnalyticsController < Dashboard::BaseController

  def show
    @analytics_mode = params[:analytics_mode] || 'revenue'

    case @analytics_mode
    when 'revenue'
      prepare_data_for_analytics_revenue
    when 'bookings'
      prepare_data_for_analytics_bookings
    when 'location_views'
      prepare_data_for_analytics_location_views
    end
  end

  def prepare_data_for_analytics_revenue
    # All paid Payment paginated
    @payments = @company.payments.paid.order('payments.paid_at DESC')
    @payments = @payments.paginate(
      :page => params[:page],
      :per_page => 20
    )

    # Charges specifically from the last 7 days
    @last_week_payments = @company.payments.paid.last_x_days(6).
      order('payments.created_at ASC')

    # Charge total summary by currency
    @all_time_totals = @company.payments.total_by_currency

    @chart = ChartDecorator.decorate(@last_week_payments)
  end

  def prepare_data_for_analytics_bookings
    # All company reservations paginated
    @reservations = @company.reservations.order('reservations.created_at DESC')
    @reservations = @reservations.paginate(
      :page => params[:page],
      :per_page => 20
    )

    @last_week_reservations = @company.reservations.last_x_days(6).order('reservations.created_at ASC')

    @chart = ChartDecorator.decorate(@last_week_reservations)
  end

  def prepare_data_for_analytics_location_views
    @visits = @company.locations_impressions.select('COUNT(impressions.*) AS impressions_count, DATE(impressions.created_at) AS impression_date').group('impression_date')

    # Visits form last 30 days
    @last_month_visits = @visits.where('DATE(impressions.created_at) >= ?', Date.current - 30.days).order('impression_date ASC')

    # All company location visits paginated
    @visits = @visits.order('DATE(impressions.created_at) DESC').paginate(
      :page => params[:page],
      :per_page => 30,
      :total_entries => @company.locations_impressions.group('DATE(impressions.created_at)').count.size
    )

    @chart = ChartDecorator.decorate(@last_month_visits)
  end
end
