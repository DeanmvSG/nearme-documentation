module Messages
  # Thread is defined by thread owner, thread recipient and thread context
  class ForThreadQuery
    def initialize(relation = UserMessage.all)
      @relation = relation
    end

    def call(user_message)
      find(*thread_arguments(user_message))
    end

    private

    def find(ids, thread_context)
      # This is special case when listing owner writes himself as a guest
      # we don't want to fetch those messages on others users conversations
      # for that listing thread
      if ids.uniq.size > 1
        @relation = @relation.where('NOT(user_messages.author_id = user_messages.thread_recipient_id
          AND user_messages.author_id = user_messages.thread_owner_id)')
      end
      @relation
        .where(thread_context_id: thread_context.id, thread_context_type: thread_context.class.to_s)
        .where('user_messages.thread_owner_id IN (:ids)', ids: ids)
        .where('user_messages.author_id IN (:ids)', ids: ids)
        .where('user_messages.thread_recipient_id IN (:ids)', ids: ids)
    end

    def thread_arguments(user_message)
      [
        [
          user_message.thread_owner,
          user_message.thread_recipient,
          user_message.author
        ].uniq.map(&:id),
        user_message.thread_context_with_deleted
      ]
    end
  end
end
