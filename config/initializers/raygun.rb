Raygun.setup do |config|
  if Rails.env.production?
    config.api_key = 'Wh44tvzgPN/Ea/JJN/i4JQ=='
  else
    config.api_key = '3VN6sPnvwRlTfwDmwhRFIA=='
  end

  config.ignore << ['Listing::NotFound', 'Location::NotFound', 'Page::NotFound', 'Reservation::NotFound']
end
