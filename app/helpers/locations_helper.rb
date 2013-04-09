module LocationsHelper
  def location_format_address(address)
    parts = address.split(',')

    content = content_tag(:strong, parts[0])

    if parts.length > 1
      content += content_tag(:span, ", #{parts[1, parts.length].join(', ')}")
    end
    content
  end

  def location_listings_json(location = @location)
    location.listings.map { |listing|
      {
        :id => listing.id,
        :name => listing.name,
        :first_available_date => listing.first_available_date.strftime("%Y/%m/%d"),
        :minimum_booking_days => listing.minimum_booking_days,
        :prices => listing.period_prices.reject { |period, price| price.nil? }.map { |period, price|
          {
            :price_cents => price.cents,
            :period      => period.to_i,
            :currency_code   => price.currency.iso_code,
            :currency_symbol => price.currency.symbol
          }
        }
      }
    }.to_json
  end
end
