class ApprovalRequest < ActiveRecord::Base
  has_paper_trail
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :instance
  belongs_to :uploader, -> { with_deleted }, class_name: 'User'
  belongs_to :owner, -> { with_deleted }, polymorphic: true
  belongs_to :approval_request_template, -> { with_deleted }

  scope :pending, lambda { with_state(:pending) }
  scope :approved, lambda { with_state(:approved) }
  scope :rejected, lambda { with_state(:rejected) }
  scope :questioned, lambda { with_state(:questionable) }

  before_create :set_defaults

  has_many :approval_request_attachments, inverse_of: :approval_request
  accepts_nested_attributes_for :approval_request_attachments, reject_if: lambda { |params| params[:file].nil? && params[:file_cache].nil? }

  validates_presence_of :message, if: lambda { |ar| ar.required_written_verification }

  def set_defaults
    self.state = 'pending'
  end

  state_machine :state, :initial => :pending do
    after_transition :approved => :pending, :do => :notify_owner_of_cancelling_acceptance
    after_transition :pending => :approved, :do => :notify_owner_of_acceptance
    after_transition :pending => :rejected, :do => :notify_owner_of_rejection
    after_transition :pending => :questionable, :do => :notify_owner_of_question

    event :review do
      transition [:approved, :rejected, :questionable] => :pending
    end

    event :accept do
      transition pending: :approved
    end

    event :reject do
      transition pending: :rejected
    end

    event :question do
      transition pending: :questionable
    end

  end

  def to_liquid
    ApprovalRequestDrop.new(self)
  end

  def message_blank_or_changed?
    self.message.blank? || (self.message_was != self.message)
  end

  def notify_owner_of_cancelling_acceptance
    owner.approval_request_acceptance_cancelled! if owner.respond_to?(:approval_request_acceptance_cancelled!)
  end

  def notify_owner_of_acceptance
    owner.approval_request_approved! if owner.respond_to?(:approval_request_approved!)
  end

  def notify_owner_of_rejection
    owner.approval_request_rejected!(self.id) if owner.respond_to?(:approval_request_rejected!)
  end

  def notify_owner_of_question
    owner.approval_request_questioned!(self.id) if owner.respond_to?(:approval_request_questioned!)
  end
end

