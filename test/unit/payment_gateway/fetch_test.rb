require 'test_helper'

class PaymentGateway::FetchPaymentGatewayTest < ActiveSupport::TestCase

  setup do
    @billing_gateway = FactoryGirl.create(:fetch_country_payment_gateway).payment_gateway
  end

  should "set fetch as processor for NZ companies with NZD currency" do
    assert_equal ['NZD'], @billing_gateway.supported_currencies
    assert_equal ['NZ'], @billing_gateway.class.supported_countries
  end

  should "set reservation as paid after success response" do
    stub_request(:post, /https:\/\/(my|demo).fetchpayments.co.nz\/webpayments\/MNSHandler.aspx/)
      .to_return(:status => 200, :body => 'VERIFIED')

    @reservation = FactoryGirl.create(:reservation_with_remote_payment, currency: 'NZD')
    @reservation.payment_response_params = SUCCESS_FETCH_RESPONSE
    assert_difference 'Charge.count' do
      assert_difference 'Payment.count' do
        @reservation.charge
      end
    end
    @reservation.reload

    assert_equal "paid", @reservation.payment_status
    assert_equal Payment.last, @reservation.payments.last
    assert_equal Charge.last, @charge = @reservation.payments.last.charges.last
    assert_equal true, @charge.success
    assert_equal SUCCESS_FETCH_RESPONSE, @charge.response
  end

  should "set reservation as failed after declined response" do
    stub_request(:post, /https:\/\/(my|demo).fetchpayments.co.nz\/webpayments\/MNSHandler.aspx/)
      .to_return(:status => 200, :body => 'DECLINED')

    @reservation = FactoryGirl.create(:reservation_with_remote_payment, currency: 'NZD')
    @reservation.payment_response_params = FAILED_FETCH_RESPONSE
    assert_difference 'Charge.count' do
      assert_difference 'Payment.count' do
        @reservation.charge
      end
    end
    @reservation.reload
    assert_equal "failed", @reservation.payment_status
    assert_equal 1, @reservation.payments.count
    @charge = @reservation.payments.last.charges.last
    refute @charge.success
    assert_equal FAILED_FETCH_RESPONSE, @charge.response
  end

  FETCH_RESPONSE = {
    "account_id" => "621380",
    "item_name" => "Super cat",
    "amount" => "1.03",
    "transaction_id" => "P150100005007408",
    "receipt_id" => "25001990",
    "verifier" => "6D1911F685372EF19E255A12691AAD74",
    "reservation_id" => "1"
  }

  SUCCESS_FETCH_RESPONSE = {
    "transaction_status" => "2",
    "response_text" => "Transaction Successful"
  }.merge(FETCH_RESPONSE)

  FAILED_FETCH_RESPONSE = {
    "transaction_status" => "11",
    "response_text" => "Transaction Failed"
  }.merge(FETCH_RESPONSE)

end
