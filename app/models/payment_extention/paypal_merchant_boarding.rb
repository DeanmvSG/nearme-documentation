module PaymentExtention::PaypalMerchantBoarding
  WP_PRO = "wp_pro"
  ADDIPMT = "addipmt"

  def boarding_url(merchant)
    @merchant = merchant
    boarding_url_host_and_path + boarding_url_params
  end

  private

  def available_products
    if @merchant.iso_country_code == 'US' && !self.express_checkout?
      products = WP_PRO
    else
      products = ADDIPMT
    end
  end

  def boarding_url_host_and_path
    prefix = test_mode? ? 'sandbox' : 'www'
    "https://#{prefix}.paypal.com/webapps/merchantboarding/webflow/externalpartnerflow?"
  end

  def boarding_url_params
    {
      "partnerId" => settings["partner_id"],
      "productIntentID" => available_products,
      "countryCode" => @merchant.iso_country_code,
      "displayMode" => "regular",
      "integrationType" => "T",
      "permissionNeeded" => merchant_permissions,
      "returnToPartnerUrl" => host + '/dashboard/company/payouts/boarding_complete',
      "receiveCredentials" => "FALSE",
      "showPermissions" => "TRUE",
      "productSelectionNeeded" => "FALSE",
      "merchantID" => @merchant.merchant_token
    }.map { |k,v| "#{k}=#{v}" }.join('&')
  end

  def merchant_permissions
    [
      "EXPRESS_CHECKOUT",
      "REFUND",
      "AUTH_CAPTURE",
      "REFERENCE_TRANSACTION",
      "BILLING_AGREEMENT",
      "DIRECT_PAYMENT"
    ].join(',')
  end

  def boarding_supported_countries
    ['US', 'GB', 'IT', 'ES', 'DE', 'FR', 'AT', 'BE', 'DK', 'NL', 'NO', 'PL', 'SE', 'CH', 'TR']
  end

end