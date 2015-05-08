class CustomMailer < InstanceMailer

  def custom_mail(step, workflow_id)
    @step = step
    return unless @step.should_be_processed?
    @workflow_alert = WorkflowAlert.find(workflow_id)
    @step.data.each do |key, value|
      instance_variable_set(:"@#{key}", value)
    end
    @step.mail_attachments(@workflow_alert).each do |attachment|
      attachments[attachment[:name].to_s] = attachment[:value]
    end
    if options[:to].blank?
      nil
    else
      WorkflowAlertLogger.new(@workflow_alert).log!
      mail(options)
    end
  end

  protected

  def get_email_for_type_with_fallback(field)
    (case @workflow_alert.send("#{field}_type")
    when 'lister'
      [@step.lister.try(:email)]
    when 'enquirer'
      [@step.enquirer.try(:email)]
    else
      InstanceAdminRole.where(name: @workflow_alert.send("#{field}_type")).first.try(:instance_admins).try(:joins, :user).try(:pluck, :email) || []
    end + (@workflow_alert.send(field).try(:split, ',') || [])).compact.uniq
  end

  def filter_emails_to_only_these_which_accepts_emails(emails)
    emails.map do |email|
      u = User.with_deleted.where(email: email, instance_id: PlatformContext.current.instance.id).first
      if u.nil? || (!u.deleted? && u.accept_emails?)
        email
      else
        nil
      end
    end.compact
  end

  def options
    @options ||= {
      template_name: @workflow_alert.template_path,
      to: filter_emails_to_only_these_which_accepts_emails(get_email_for_type_with_fallback('recipient')),
      from: get_email_for_type_with_fallback('from'),
      reply_to: get_email_for_type_with_fallback('reply_to'),
      cc: filter_emails_to_only_these_which_accepts_emails(@workflow_alert.cc.try(:split, ',') || []),
      bcc: filter_emails_to_only_these_which_accepts_emails(@workflow_alert.bcc.try(:split, ',') || []),
      subject: Liquid::Template.parse(@workflow_alert.subject).render(@step.data.merge('platform_context' => PlatformContext.current.decorate).stringify_keys, filters: [LiquidFilters]),
      layout_path: @workflow_alert.layout_path,
      transactable_type_id: @step.transactable_type_id
    }
  end
end
