require 'test_helper'

class ReservationsServiceTest < ActiveSupport::TestCase

  context '#reservation_build_documents' do
    setup do
      @listing = FactoryGirl.create(:transactable)
      @user = FactoryGirl.create(:user)
      @date = @listing.first_available_date
      @attributes = {
        :dates => [@date.to_s(:db)]
      }
      @instance = Instance.first || create(:instance)
      FactoryGirl.create(:document_requirement, item: @listing)
      FactoryGirl.create(:upload_obligation, level: UploadObligation::LEVELS[0], item: @listing)
      @reservation_request = ReservationRequest.new(@listing, @user, PlatformContext.new(@instance), @attributes)
      @reservation_service = Listings::ReservationsService.new(@user, @reservation_request)
    end

    should 'documents are built' do
      @reservation_service.build_documents
      assert @reservation_request.reservation.payment_documents.present?
    end

    should 'documents are not built' do
      assert @reservation_request.reservation.payment_documents.empty?
    end

  end

end
