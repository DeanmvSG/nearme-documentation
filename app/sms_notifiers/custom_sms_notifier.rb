class CustomSmsNotifier < InstanceSmsNotifier

  def custom_sms(step, workflow_alert_id)
    @step = step
    @workflow_alert = WorkflowAlert.find(workflow_alert_id)
    if @step.should_be_processed? && user.present?
      # the idea with callback is to truncate part of the content correctly. For example user_message sms, it's like:
      # Hello, {{ message.author.name }}, u got message {{ message.body }}. Check {{ listing.url }}
      # If we just truncate this mussage to required 160 chars, the url will be missing. Instead, we want to calculate the size
      # of the message without the message.body, then we will truncate the body to 160 - <size of the rest of the message>.
      # This way we will everything will be fine, the url will be present etc. Tricky, but well, working. We have test coverage for this.
      @step.callback_to_prepare_data_for_check
      set_variables
      @step.callback_to_adjust_data_after_check(sms(options))
      set_variables
      WorkflowAlertLogger.new(@workflow_alert).log!
      sms(options)
    else
      ::SmsNotifier::NullMessage.new
    end
  end

  protected

  def set_variables
    @step.data.each do |key, value|
      instance_variable_set(:"@#{key}", value)
    end
  end

  def options
    {
      template_name: @workflow_alert.template_path,
      to: user.try(:full_mobile_number),
      fallback: { email: user.try(:email) }
    }
  end

  def user
    case @workflow_alert.recipient_type
    when 'lister'
      @step.lister if @step.lister.accepts_sms?
    when 'enquirer'
      @step.enquirer if @step.enquirer.accepts_sms?
    when 'administrator'
      InstanceAdmin.includes(:user).map { |ia| ia.user if ia.user.accepts_sms? }.compact.first
    end
  end


end
