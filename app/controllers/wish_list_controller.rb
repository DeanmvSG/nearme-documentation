class WishListController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_wish_lists_enabled
  before_filter :find_item

  def add_item
    if current_user.default_wish_list.items.find_by(wishlistable: @item)
      redirect_to redirection_path(@item), notice: t('wish_lists.notices.already_listed')
      return
    end

    wish_list_item = current_user.default_wish_list.items.create wishlistable: @item

    respond_to do |format|
      format.html { redirect_to redirection_path(wish_list_item.wishlistable), notice: t('wish_lists.notices.item_added') }
      format.js
    end
  end

  def remove_item
    current_user.default_wish_list.items.find_by(wishlistable: @item).destroy

    respond_to do |format|
      format.html { redirect_to redirection_path(@item), notice: t('wish_lists.notices.item_removed') }
      format.js
    end
  end

  private

  def check_wish_lists_enabled
    redirect_to(root_path, notice: t('wish_lists.notices.wish_lists_disabled')) unless platform_context.instance.wish_lists_enabled?
  end

  def redirection_path(object)
    case object
    when Transactable 
      object.decorate.show_path
    when Location
      object.listings.searchable.first.try(:decorate).try(:show_path) || root_path
    else
       polymorphic_path(object)
    end
  end

  def find_item
    klass_name = params[:wishlistable_type]
    unless WishListItem::PERMITTED_CLASSES.include?(klass_name)
      raise WishListItem::NotPermitted, "Class #{klass_name} is not permitted as wish list item. You have to add it to WishListItem::PERMITTED_CLASSES"
    end

    @item = klass_name.constantize.find(params[:object_id])
  end
end
