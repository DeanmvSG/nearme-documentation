class Translation < ActiveRecord::Base

  belongs_to :instance

  scope :defaults_for, lambda { |locale| where('locale = ? AND instance_id IS NULL', locale) }
  scope :for_instance, lambda { |instance_id| where('instance_id = ?', instance_id) }
  scope :defaults, -> { where('instance_id is null') }
  scope :updated_after, lambda { |updated_at| where('updated_at > ?', updated_at.to_time) }
  scope :default_and_custom_translations_for_instance, -> (instance_id) { where('locale = ? AND (instance_id IS NULL OR instance_id = ? )', 'en', instance_id) }

  validates :key, presence: true,
    uniqueness: { scope: [:instance_id, :locale], case_sensitive: false},
    on: :instance_admin
  validates :value, presence: true, on: :instance_admin
  validate :key_format, on: :instance_admin

  include Cacheable

  def key_format
    if key.match /[!@#$%^&*()\-+:\/'";,?}{\[\]\\<>\|=±`~§]|\s/
      errors.add :key, 'Unsupported format. Valid format: this.is.my_custom_key'
    end
  end

end
