FactoryGirl.define do
  factory :workflow_alert do
    workflow_step
    sequence(:name) {|n| "Workflow Alert #{n}"}
    recipient_type 'lister'
    alert_type 'email'
    template_path 'not/existing'

    factory :workflow_alert_lister do
      recipient_type 'lister'
    end

    factory :workflow_alert_enquirer do
      recipient_type 'enquirer'
    end

    factory :workflow_alert_administrator do
      recipient_type 'administrator'
    end

  end
end
