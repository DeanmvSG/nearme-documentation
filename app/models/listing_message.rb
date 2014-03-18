class ListingMessage < ActiveRecord::Base

  attr_accessor :replying_to_id

  belongs_to :author, class_name: 'User' # person that wrote this message
  belongs_to :owner, class_name: 'User' # guest that started conversation
  belongs_to :listing

  validates_presence_of :author_id
  validates_presence_of :owner_id
  validates_presence_of :body, message: "Message can't be blank."
  validates_length_of :body, maximum: 2000, message: "Message cannot have more than 2000 characters."

  scope :for_thread, ->(listing, listing_message) {
    where(listing_id: listing.id, owner_id: listing_message.owner_id)
  }

  scope :by_created, -> {order('created_at desc')}

  def previous_in_thread
    ListingMessage.find(replying_to_id)
  end

  def first_in_thread?
    replying_to_id.blank?
  end

  def unread?
    !read?
  end

  def unread_for?(user)
    unread? && user.id != author_id
  end

  def archived_column_for(user)
    "archived_for_#{kind_for(user)}"
  end

  def archived_for?(user)
    send archived_column_for(user)
  end

  def to_liquid
    ListingMessageDrop.new(self)
  end

  def message_from_guest?
    owner_id == author_id
  end

  def send_notification
    if message_from_guest?
      ListingMessageMailer.enqueue.email_message_from_guest(self)
    else
      ListingMessageMailer.enqueue.email_message_from_host(self)
    end
  end

  def recipient
    message_from_guest? ? listing.administrator : owner
  end

  def listing_with_deleted
    @listing_with_deleted ||= Listing.with_deleted.find_by_id(listing_id)
  end

  private

  def kind_for(user)
    if user.id == owner_id
      :owner
    else
      :listing
    end
  end

end
