class LocationDecorator < Draper::Decorator
  include Draper::LazyHelpers

  delegate_all

end

