class SellerAttachment::Fetcher
  def initialize(user)
    @user = user
  end

  def attachments_for(attachable)
    if attachable.creator_id == @user.id
      attachable.attachments
    else
      attachable.attachments.where(user_id: [@user.id, attachable.creator_id])
    end.order('created_at DESC')
  end

  def has_access_to?(attachment)
    fail ArgumentError if attachment.access_level == 'disabled'
    return true if attachment.accessible_to_all?
    return false if @user.nil?
    return true if attachment.user_id == @user.id
    return !!@user if attachment.accessible_to_users?

    if attachment.accessible_to_listers?
      @user.seller_profile.present?
    elsif attachment.accessible_to_enquirers?
      @user.buyer_profile.present?
    elsif attachment.assetable.is_a?(Transactable)
      if attachment.assetable.creator_id == @user.id
        true
      elsif attachment.accessible_to_purchasers?
        attachment.assetable.line_item_orders.confirmed.where(user_id: @user.id).any?
      elsif attachment.accessible_to_collaborators?
        attachment.assetable.approved_transactable_collaborators.for_user(@user).any?
      else
        fail ArgumentError
      end
    end
  end

  protected

  def build_scope_for(_attachable)
  end

  def instance
    @instance ||= PlatformContext.current.instance
  end
end