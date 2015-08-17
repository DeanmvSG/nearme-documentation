class CustomAttributes::CustomAttribute < ActiveRecord::Base
  # defined in vendor/gems/custom_attributes/lib/custom_attributes/concerns
  include CustomAttributes::Concerns::Models::CustomAttribute
  include Cacheable

  has_paper_trail
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  after_save :create_translations

  scope :searchable, -> { where(searchable: true) }

  validates_presence_of :valid_values, if: :searchable

  def create_translations
    ::CustomAttributes::CustomAttribute::TranslationCreator.new(self).create_translations!
    expire_cache_key(cache_type: 'Translation')
  end

  def expire_cache_options
    { target_type: self.target_type }
  end
end

