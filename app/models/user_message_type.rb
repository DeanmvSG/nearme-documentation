# frozen_string_literal: true
class UserMessageType < ActiveRecord::Base
  auto_set_platform_context
  scoped_to_platform_context
  acts_as_custom_attributes_set

  belongs_to :instance

  DEFAULT = 'default'

  def self.default
    find_by(type: DEFAULT)
  end
end
