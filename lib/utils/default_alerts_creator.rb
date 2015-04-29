class Utils::DefaultAlertsCreator

  def create_all_workflows!
    Utils::DefaultAlertsCreator::SignUpCreator.new.create_all!
    Utils::DefaultAlertsCreator::ReservationCreator.new.create_all!
    Utils::DefaultAlertsCreator::ListingCreator.new.create_all!
    Utils::DefaultAlertsCreator::RecurringBookingCreator.new.create_all!
    Utils::DefaultAlertsCreator::PayoutCreator.new.create_all!
    Utils::DefaultAlertsCreator::SupportCreator.new.create_all!
    Utils::DefaultAlertsCreator::RfqCreator.new.create_all!
    Utils::DefaultAlertsCreator::InstanceAlertsCreator.new.create_all!
    Utils::DefaultAlertsCreator::InquiryCreator.new.create_all!
    #Utils::DefaultAlertsCreator::RecurringCreator.new.create_all!
    Utils::DefaultAlertsCreator::UserMessageCreator.new.create_all!
    Utils::DefaultAlertsCreator::DataUploadCreator.new.create_all!
    Utils::DefaultAlertsCreator::LineItemCreator.new.create_all!
    Utils::DefaultAlertsCreator::SavedSearchCreator.new.create_all!
    Utils::DefaultAlertsCreator::OrderCreator.new.create_all!
  end

end

