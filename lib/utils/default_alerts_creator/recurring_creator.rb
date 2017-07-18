class Utils::DefaultAlertsCreator::RecurringCreator < Utils::DefaultAlertsCreator::WorkflowCreator
  def create_all!
    create_share_email!
  end

  def create_share_email!
    create_alert!(associated_class: WorkflowStep::RecurringWorkflow::Share, name: 'share email', path: 'recurring_mailer/share', subject: "Share your listing '{{listing.name}}' at {{listing.location.street}} and increase bookings!", alert_type: 'email', recipient_type: 'lister')
  end

  protected

  def workflow_type
    'recurring'
  end
end