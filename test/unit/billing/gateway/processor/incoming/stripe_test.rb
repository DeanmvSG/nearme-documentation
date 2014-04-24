require 'test_helper'
require 'vcr_setup'

class Billing::Gateway::Processor::Incoming::StripeTest < ActiveSupport::TestCase

  setup do
    @instance = FactoryGirl.create(:instance_test_mode)
    @user = FactoryGirl.create(:user)
    @instance.instance_payment_gateways << FactoryGirl.create(:stripe_instance_payment_gateway)
    @stripe_processor = Billing::Gateway::Processor::Incoming::Stripe.new(@user, @instance, 'USD')
    ActiveMerchant::Billing::Base.mode = :test
    @reservation = FactoryGirl.create(:reservation_with_credit_card)
  end

  should "#authorize" do
    VCR.use_cassette('payment_gateways_stripe_authorize') do
      response = authorize!
      assert response.success?
      assert response.authorization.present?
      assert_equal response.authorization, @reservation.authorization_token
    end
  end

  should "#charge" do
    VCR.use_cassette('payment_gateways_stripe_charge') do
      authorize!
      charge = capture!

      assert charge.response.is_a?(Hash)
      assert_equal charge.response["id"], @reservation.authorization_token
      assert_equal charge.amount, @reservation.total_amount_cents
    end
  end

  should "#refund" do
    VCR.use_cassette('payment_gateways_stripe_refund') do
      authorize!
      charge = capture!
      refund = @stripe_processor.refund(@reservation.total_amount_cents, charge, charge.response)

      assert refund.response.is_a?(Hash)      
      assert_equal charge.response["id"], refund.response["id"]
      assert refund.response["refunded"]
      assert_equal refund.amount, charge.amount
    end
  end

  protected

  def credit_card
    ActiveMerchant::Billing::CreditCard.new(
      first_name: @user.first_name,
      last_name: @user.last_name,
      month: '5',
      year: '2020',
      number: '4242424242424242',
      verification_value: '411'
    )
  end

  def authorize!
    @stripe_processor.authorize(credit_card, @reservation)
  end

  def capture!
    reservation_charge = @reservation.reservation_charges.create!(
      subtotal_amount: @reservation.subtotal_amount,
      service_fee_amount_guest: @reservation.service_fee_amount_guest,
      service_fee_amount_host: @reservation.service_fee_amount_host
    )

    @stripe_processor.charge(@reservation, reservation_charge.total_amount_cents, reservation_charge)
  end
end
