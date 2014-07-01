class Support::Faq < ActiveRecord::Base
  self.table_name = 'support_faqs'

  has_paper_trail :ignore => [ :deleted_at, :created_at, :updated_at, :created_by_id, :updated_by_id, :deleted_by_id ]
  acts_as_paranoid
  scoped_to_platform_context

  include RankedModel

  auto_set_platform_context

  ranks :position, with_same: :instance_id

  # attr_accessible :question, :answer

  belongs_to :instance

  validates :question, presence: true
  validates :answer, presence: true
end
