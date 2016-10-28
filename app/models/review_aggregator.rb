class ReviewAggregator
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def total
    about_seller + about_buyer + left_by_seller + left_by_buyer_about_host + left_by_buyer_about_transactable
  end

  private

  def about_seller
    Review.about_seller(user).count
  end

  def about_buyer
    Review.about_buyer(user).count
  end

  def left_by_seller
    Review.left_by_seller(user).count
  end

  def left_by_buyer_about_host
    Review.left_by_buyer(user).active_with_subject(RatingConstants::HOST).count
  end

  def left_by_buyer_about_transactable
    Review.left_by_buyer(user).active_with_subject(RatingConstants::TRANSACTABLE).count
  end
end
