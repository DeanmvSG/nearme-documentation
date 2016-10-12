class WorkflowStep::CommenterWorkflow::BaseStep < WorkflowStep::BaseStep
  def initialize(comment_id)
    @comment = Comment.find_by(id: comment_id)
    @commentable = @comment.try(:commentable)
    @user = @comment.try(:creator)
  end

  def enquirer
    @user
  end

  def lister
    fail NotImplementedError.new("#{self.class.name} has to define lister method")
  end

  def workflow_type
    'commenter_workflow'
  end

  def should_be_processed?
    @comment.present? && @commentable.present? # && @user.id != lister.id
  end
end
