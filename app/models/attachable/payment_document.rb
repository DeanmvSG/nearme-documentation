class Attachable::PaymentDocument < Attachable::Attachment
  mount_uploader :file, ::PaymentDocumentUploader

  has_one :payment_document_info, class_name: 'Attachable::PaymentDocumentInfo', foreign_key: 'attachment_id', dependent: :destroy

  delegate :document_requirement, to: :payment_document_info

  accepts_nested_attributes_for :payment_document_info

  validates_presence_of :file

  self.per_page = 20

  scope :uploaded_by, ->(user_id){ where(user_id: user_id) }
  scope :not_uploaded_by, ->(user_id){ where.not(user_id: user_id) }

  def is_file_required?
    payment_document_info.try(:document_requirement).try(:is_file_required?) || false
  end
end
