class CreditCard::StripeDecorator

  attr_accessor :credit_card

  def initialize(credit_card)
    @credit_card = credit_card
  end

  def active?
    response.success?
  end

  def token
    @token ||= response.params["object"] == 'card' ? response.params["id"] : response.params["default_source"]
  end

  def response
    @response ||= YAML.load(credit_card.response)
  end

  def expires_at
    nil
  end

  def name
    (response.params['name'].presence || response.params["sources"]["data"].detect { |cc| cc["id"] == token }["name"]) rescue nil
  end

  def last_4
    (response.params['last4'].presence || response.params["sources"]["data"].detect { |cc| cc["id"] == token }["last4"]) rescue nil
  end
end

