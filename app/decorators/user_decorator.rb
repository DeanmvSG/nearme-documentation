class UserDecorator < Draper::Decorator
  delegate_all

  def job_title_and_company_name
    result = []
    result << job_title if job_title.present?
    result << company_name if company_name.present?
    result.join(" at ")
  end

  def current_location_and_industry
    result = []
    result << current_location if current_location.present?
    result << industries.map(&:name).join(", ") if industries.present?
    result.join(" | ")
  end

  def unread_listing_message_threads
    listing_messages_decorator.inbox.unread
  end

  private
  def listing_messages_decorator
    @listing_messages_decorator ||= ListingMessagesDecorator.new(listing_messages, object)
  end
end
