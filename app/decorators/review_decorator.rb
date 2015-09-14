class ReviewDecorator < Draper::Decorator
  include Draper::LazyHelpers
  include FeedbackDecoratorHelper

  delegate_all

  def date_format
    if created_at.to_date == Time.zone.today
      I18n.t('decorators.review.today')
    else
      I18n.l(created_at, format: :day_month_year)
    end
  end

  def transactable_path
    if reviewable.respond_to?(:transactable_id)
      listing_path(reviewable.transactable_id)
    else
      product_path(reviewable.product)
    end
  end

  def link_to_object
    return I18n.t('instance_admin.manage.reviews.index.missing') if reviewable.nil?

    case object.rating_system.try(:subject)
      when RatingConstants::HOST then link_to_new_tab(I18n.t('helpers.reviews.user'), profile_path(reviewable.seller_type_review_receiver))
      when RatingConstants::GUEST then link_to_new_tab(I18n.t('helpers.reviews.user'), profile_path(reviewable.buyer_type_review_receiver))
      when RatingConstants::TRANSACTABLE then link_to_new_tab(I18n.t('helpers.reviews.product'), transactable_path)
    end
  end

  def link_to_new_tab(name, path)
    h.link_to name, path, target: "_blank"
  end

  def link_to_seller_profile
    if reservation?
      h.link_to t('dashboard.reviews.feedback.view_seller_profile'), user_path(reviewable.creator)
    else
      h.link_to t('dashboard.reviews.feedback.view_seller_profile'), user_path(reviewable.product.administrator)
    end
  end

  def show_reviewable_info
    info = if params[:option] == 'reviews_left_by_seller' || params[:option] == 'reviews_left_by_buyer'
      if object.rating_system.try(:subject) == 'transactable'
        get_product_info
      else
        get_user_info
      end
    else
      own_info
    end

    reviewable_info(info)
  end

  def feedback_object
    object.reviewable
  end

  private

  def reviewable_info(attrs)
    h.image_tag(attrs[:photo]) + content_tag(:p, attrs[:name], class: 'name-info')
  end

  def own_info
    user_info_for(user)
  end

  def get_user_info
    user_info_for(object.subject == RatingConstants::HOST ? seller : buyer)
  end

  def user_info_for(target_user)
    {photo: target_user.avatar_url, name: target_user.first_name}
  end

  def info_for_reservation
    {photo: reservation_photo, name: reviewable.listing.try(:name)}
  end

  def info_for_line_item
    {photo: line_item_photo, name: reviewable.product.try(:name)}
  end

  def reservation_photo
    if reviewable.listing && reviewable.listing.has_photos?
      reviewable.listing.photos.first.image_url(:medium)
    else
      default_item_photo
    end
  end

  def line_item_photo
    if reviewable.product && reviewable.product.images.first.present?
      reviewable.product.images.first.image_url(:medium)
    else
      default_item_photo
    end
  end

  def default_item_photo
    "ratings/reviews-placeholder.png"
  end

  def get_product_info
    reservation? ? info_for_reservation : info_for_line_item
  end
end
