class WorkflowStep::BaseStep

  def self.belongs_to_transactable_type?
    false
  end

  def invoke!
    alerts.each do |alert|
      WorkflowAlert::InvokerFactory.get_invoker(alert).invoke!(self)
    end
  end

  def should_be_processed?
    true
  end

  def mail_attachments(alert)
    []
  end

  # these methods has been implemented for SMS - we might want to truncate one variable, but we don't know
  # the size of the rest of the message ahead of time. think of string like "{{ a }} {{ b }} {{ c }}".
  # If we want the string to be no longer than 160 characters, but we know that a and c together for sure won't
  # exceed it, but b might, and we want to be sure that both a and c are included in the message, we need to
  # have a way to check the size of evaluated {{ a }} and {{ c }}, then we can just truncate b to 160 - size of a+c.
  # These methods allows to do just that. They are used for example for UserMessage::Created
  def callback_to_prepare_data_for_check
  end

  def callback_to_adjust_data_after_check(rendered_view)
  end

  def transactable_type_id
    nil
  end

  protected

  def alerts
    workflow_step.try(:workflow_alerts) || []
  end

  def workflow
    Workflow.for_workflow_type(workflow_type).first
  end

  def workflow_step
    workflow.try(:workflow_steps).try(:for_associated_class, self.class.to_s).try(:includes, :workflow_alerts).try(:first)
  end

  def workflow_type
    raise NotImplementedError.new("#{self.class.name} must implemented workflow_type method")
  end

  def lister
    nil
  end

  def enquirer
    nil
  end

  def data
    {}
  end

end

