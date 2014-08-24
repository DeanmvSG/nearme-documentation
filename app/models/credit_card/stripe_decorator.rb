class CreditCard::StripeDecorator

  attr_accessor :credit_card

  def initialize(credit_card)
    @credit_card = credit_card
  end

  def token
    @token ||= response.params["object"] == 'card' ? response.params["id"] : response.params["cards"]["data"].last["id"]
  end

  def response
    @response ||= YAML.load(credit_card.response)
  end
end

