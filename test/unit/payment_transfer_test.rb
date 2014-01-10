require 'test_helper'
require 'helpers/reservation_test_support'

class PaymentTransferTest < ActiveSupport::TestCase
  include ReservationTestSupport

  def setup
    stub_mixpanel
    @company = prepare_company_with_charged_reservations(:reservation_count => 2)

    @reservation_1 = @company.reservations[0]
    @reservation_2 = @company.reservations[1]

    @reservation_charges = [
      @reservation_1.reservation_charges.to_a,
      @reservation_2.reservation_charges.to_a
    ].flatten
  end

  context "creating" do
    setup do
      @payment_transfer = @company.payment_transfers.build
    end

    should "only allow charges of the same currency" do
      rc = ReservationCharge.create!(
        :reservation => @reservation_1,
        :subtotal_amount => 10,
        :service_fee_amount_guest => 1,
        :service_fee_amount_host => 2,
        :currency => 'CAD'
      )

      @payment_transfer.reservation_charges = [@reservation_charges, rc].flatten
      assert !@payment_transfer.save
      assert @payment_transfer.errors[:currency].present?
    end

    should "assign currency attribute" do
      @payment_transfer.reservation_charges = @reservation_charges
      @payment_transfer.save!
      @payment_transfer.reload

      assert_equal @reservation_charges.first.currency,
        @payment_transfer.currency
    end

    should "calculate amounts" do
      @payment_transfer.reservation_charges = @reservation_charges
      @payment_transfer.save!

      assert_equal @reservation_charges.map(&:subtotal_amount).sum - @reservation_charges.map(&:service_fee_amount_host).sum,
        @payment_transfer.amount

      assert_equal @reservation_charges.map(&:service_fee_amount_guest).sum,
        @payment_transfer.service_fee_amount_guest
      assert_equal @reservation_charges.map(&:service_fee_amount_host).sum,
        @payment_transfer.service_fee_amount_host
    end
  end

  context "#gross_amount_cents" do
    should "be the sum of the charge subtotals and the service fees" do
      pt = PaymentTransfer.new
      pt.amount_cents = 50_00
      pt.service_fee_amount_guest_cents = 10_00
      pt.service_fee_amount_host_cents = 15_00
      assert_equal 75_00, pt.gross_amount_cents
    end
  end

  context ".pending" do
    should "include all PaymentTransfers that haven't been transferred" do
      pt1 = @company.payment_transfers.create!
      pt2 = @company.payment_transfers.create!
      pt3 = @company.payment_transfers.create!(:transferred_at => Time.now)

      assert @company.payment_transfers.pending.include?(pt1)
      assert @company.payment_transfers.pending.include?(pt2)
      assert !@company.payment_transfers.pending.include?(pt3)
    end
  end
end
