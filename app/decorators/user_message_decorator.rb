class UserMessageDecorator < Draper::Decorator
  delegate_all

  def recipient_name
    recipient.name
  end

  def css_class(user = nil)
    classes = []
    classes << (read_for?(user) ? 'read' : 'unread')
    if user
      if author == user
        classes << 'my-message'
      else
        classes << 'foreign-message'
      end
    end
    classes.join(' ')
  end

  def available_for_reply?
    thread_context.present? && thread_owner.present? && thread_recipient.present?
  end

end
