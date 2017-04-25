# frozen_string_literal: true
class WishListItemDrop < BaseDrop
  include CurrencyHelper

  # Required when calling methods here included from drops
  # These end up being available in drops but there's nothing
  # we can do at this point about it and they're not actually
  # dangerous
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TagHelper

  # @return [Object]
  attr_reader :wishlistable, :wish_list_item

  def initialize(wish_list_item)
    @wish_list_item = wish_list_item
    @wishlistable = @wish_list_item.wishlistable
  end

  # @!method id 
  #   @return [Integer] numeric identifier for the object
  delegate :id, to: :wish_list_item

  # @!method wishlistable_id
  #   @return [Integer] numeric identifier of the wishlisted object
  #   @todo -- remove, DIY
  # @!method wishlistable_name
  #   @return [String] name of the associated object (wishlisted object)
  #   @todo -- remove, DIY
  delegate :id, :name, to: :wishlistable, prefix: true
  alias name wishlistable_name 

  # @return [Boolean] whether the associated object (wishlisted) is present
  # @todo -- remove, DIY
  def wishlistable_present?
    @wish_list_item.wishlistable.present?
  end

  # @return [String] path to the associated object (wishlisted object)
  # @todo -- remove, url filter
  def wishlistable_path
    polymorphic_wishlistable_path(@wishlistable)
  end

  # @return [String] type (downcased class name) of the wishlisted object
  def wishlistable_type
    @wishlistable.class.name.downcase
  end
  alias type wishlistable_type

  # @return [String] name of the associated company (company to which the wishlisted object belongs)
  def company_name
    @wishlistable.try(:companies).try(:first).try(:name) || @wishlistable.company.name
  end

  # @return [String, nil] price of the associated wishlisted item, if present, otherwise the address
  #   of the associated wishlisted item
  # @todo - lets give users control over formatting.
  # also... method *price* returning price or address?
  def price
    if @wishlistable.try(:price)
      number_to_currency_symbol @wishlistable.currency, @wishlistable.price
    else
      @wishlistable.try(:address)
    end
  end

  # @return [LocationDrop, nil] location of the wishlistable
  # @todo -- remove, DIY
  def wishlistable_location
    @wishlistable.try(:location)
  end

  # @return [String] path to the wish list item in the dashboard
  # @todo - remove for url filter
  def dashboard_wish_list_item_path
    routes.dashboard_wish_list_item_path(@wish_list_item)
  end

  # @return [String] URL to the image of the wishlisted item, or a placeholders if not present
  # @todo - DIY - lets use something smarter.
  # code smell. from hardcoding things to everything else.
  # Also... wish_list_item_decorator seems to have a lot of logic in there which is not consistent with this
  def image_url
    if @wishlistable.try(:avatar_url)
      @wishlistable.avatar_url(:big)
    elsif @wishlistable.try(:images)
      @wishlistable.images.empty? ? no_image : asset_url(@wishlistable.images.first.image_url)
    else
      @wishlistable.photos_metadata.any? ? @wishlistable.photos_metadata[0][:golden] : no_image
    end
  end

  # @return [String] path to the wishlisted item
  # @todo - check if  wish_list_item_decorator method under the same name could be used or not
  def polymorphic_wishlistable_path(_wishlistable)
    if @wishlistable.is_a?(Transactable)
      @wishlistable.decorate.show_path
    elsif @wishlistable.is_a?(Location)
      @wishlistable.listings.searchable.first.try(:decorate).try(:show_path)
    elsif @wishlistable.is_a?(User)
      @wishlistable.decorate.show_path
    end
  end

  # @return [String] URL to the default (placeholder) wishlisted item image
  # @todo - this shouldnt be hardcoded as its already outdated
  def no_image
    asset_url 'placeholders/895x554.gif'
  end
end
