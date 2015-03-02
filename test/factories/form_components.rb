FactoryGirl.define do
  factory :form_component do
    sequence(:name) { |n| "Section #{n}" }
    form_componentable { TransactableType.first.presence || FactoryGirl.create(:transactable_type_listing) }
    form_type { FormComponent::SPACE_WIZARD }

    form_fields { [{'company' => 'name'}, {'company' => 'address'}, {'company' => 'industries'}, {'location' => 'name'}, {'location' => 'description'}, {'location' => 'phone'}, {'location' => 'location_type'}, {'location' => 'address'}, { 'transactable' => 'price' }, {'transactable' => 'description'}, { 'transactable' => 'photos' }, {'transactable' => 'quantity'}, { 'transactable' => 'name' }, { 'transactable' => 'listing_type' }, { 'user' => 'phone'}, { 'user' => 'approval_requests'}, { 'user' => 'first_name' }, { 'user' => 'last_name' } ] }

    factory :form_component_transactable do
      form_type { FormComponent::TRANSACTABLE_ATTRIBUTES }

      form_fields { [ {'transactable' => 'schedule'},{'transactable' => 'location_id'}, { 'transactable' => 'price' }, {'transactable' => 'description'}, { 'transactable' => 'photos' }, {'transactable' => 'quantity'}, { 'transactable' => 'name' }, { 'transactable' => 'listing_type' }, { 'transactable' => 'waiver_agreement_templates'}, {'transactable' => 'documents_upload'} ] }
    end

  end

end
