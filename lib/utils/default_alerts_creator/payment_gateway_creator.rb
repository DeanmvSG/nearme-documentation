class Utils::DefaultAlertsCreator::PaymentGatewayCreator < Utils::DefaultAlertsCreator::WorkflowCreator

  def create_all!
    create_notify_host_about_merchant_account_approved_email!
    create_notify_host_about_merchant_account_declined_email!
    create_notify_host_about_payout_failure_email!
  end

  def create_notify_host_about_merchant_account_approved_email!
    create_alert!({associated_class: WorkflowStep::PaymentGatewayWorkflow::MerchantAccountApproved, name: 'notify_host_about_merchant_account_approved_email', path: 'payment_gateway_mailer/notify_host_of_merchant_account_approval', subject: "Your payout information has been approved", alert_type: 'email', recipient_type: 'lister'})
  end

  def create_notify_host_about_merchant_account_declined_email!
    create_alert!({associated_class: WorkflowStep::PaymentGatewayWorkflow::MerchantAccountDeclined, name: 'notify_host_about_merchant_account_declined_email', path: 'payment_gateway_mailer/notify_host_of_merchant_account_declinal', subject: "Your payout information has been declined", alert_type: 'email', recipient_type: 'lister'})
  end

  def create_notify_host_about_payout_failure_email!
    create_alert!({associated_class: WorkflowStep::PaymentGatewayWorkflow::DisbursementFailed, name: 'notify_host_about_payout_failure_email', path: 'payment_gateway_mailer/notify_host_about_payout_failure_email', subject: "Automatic payout failed", alert_type: 'email', recipient_type: 'lister'})
  end

  protected

  def workflow_type
    'payment_gateway'
  end

end
