module SearchHelper
  def search_availability_dates_start
    params[:availability].present? && params[:availability][:dates].present? && search[:availability][:dates][:start] ||
      Time.now.strftime('%b %-e')
  end

  def search_availability_dates_end
    params[:availability].present? && params[:availability][:dates].present? && search[:availability][:dates][:end] ||
      Time.now.advance(:weeks => 1).strftime('%b %-e')
  end

  def search_availability_quantity
    params[:availability].present? && params[:availability][:quantity].to_i
  end

  def search_organizations
    params[:organizations].present? && params[:organizations].map(&:to_i) || []
  end

  def search_amenities
    params[:amenities].present? && params[:amenities].map(&:to_i) || []
  end

  def search_price_min
    params[:price].present? && params[:price][:min]
  end

  def search_price_max
    params[:price].present? && params[:price][:max]
  end

end
