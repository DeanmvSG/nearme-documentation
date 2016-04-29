FactoryGirl.define do
  factory :custom_attribute, class: 'CustomAttributes::CustomAttribute' do
    sequence(:name) { |n| "Attribute #{n}" }
    attribute_type "string"
    label 'My Label'
    hint 'this is my hint'
    required 0

    after(:create) do |attribute|
      CustomAttributes::CustomAttribute.clear_cache(attribute.target_type, attribute.target_id) if attribute.target_type && attribute.target_id
      I18N_DNM_BACKEND.update_cache(PlatformContext.current.instance.id) if defined? I18N_DNM_BACKEND
    end

    trait :listing_types do
      name 'listing_type'
      valid_values { ["Desk", "Meeting Room", "Office Space", "Salon Booth"] }
      attribute_type 'string'
      required 1
    end

    factory :custom_attribute_required do
      validation_rules { { presence: {} } }
    end

    factory :custom_attribute_array do
      name "array"
      attribute_type "array"
    end

    factory :custom_attribute_input do
      html_tag 'input'
      placeholder 'My Placeholder'
    end

    factory :custom_attribute_textarea do
      html_tag 'textarea'
      placeholder 'My Placeholder'
    end

    factory :custom_attribute_check_box do
      html_tag 'check_box'
    end

    factory :custom_attribute_switch do
      html_tag 'switch'
    end

    factory :custom_attribute_check_box_list do
      html_tag 'check_box_list'
      valid_values { ['Value One', 'Value Two'] }
    end

    factory :custom_attribute_radio_buttons do
      html_tag 'radio_buttons'
      valid_values { ['Value One', 'Value Two'] }
    end

    factory :custom_attribute_select do
      html_tag 'select'
      prompt 'My Prompt'
      valid_values { ['Value One', 'Value Two'] }
    end

    factory :custom_attibute_license do
      name 'license_number'
      attribute_type 'string'
      html_tag 'input'
      required '1'
      public '1'
      label 'License number'
      validation_rules { { presence: {} } }
    end

    factory :user_custom_attribute do
      target { InstanceProfileType.default.first || FactoryGirl.create(:instance_profile_type) }
      attribute_type 'string'
      factory :required_user_custom_attribute do
        validation_rules { { 'presence' => {} } }
      end

    end

  end
end
