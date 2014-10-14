require 'test_helper'

class InstanceAdmin::Manage::TransactableTypes::CustomAttributesControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user)
    @instance = FactoryGirl.create(:instance)
    PlatformContext.any_instance.stubs(:instance).returns(@instance)
    @transactable_type = FactoryGirl.create(:transactable_type)
    InstanceAdminAuthorizer.any_instance.stubs(:instance_admin?).returns(true)
    InstanceAdminAuthorizer.any_instance.stubs(:authorized?).returns(true)
    sign_in @user
  end

  context 'create' do

    should 'create a new transactable_type' do
      assert_difference 'CustomAttributes::CustomAttribute.count', 1 do
        post :create, {"custom_attribute"=>{"name"=>"new_attribute", "label"=>"attribute label", "attribute_type"=>"string", "html_tag"=>"select", "placeholder"=>"", "prompt"=>"my prompt", "default_value"=>"value5", "hint"=>"this is hint", "public"=>"1", "valid_values"=>"value1, value2, value5", "input_html_options_string"=>"class => myclass, style => color: red", "wrapper_html_options_string"=>"class => wrapper-class, style => color: blue"}, transactable_type_id: @transactable_type.id}
      end
      custom_attribute = assigns(:custom_attribute)
      assert_equal 'new_attribute', custom_attribute.name
      assert_equal 'attribute label', custom_attribute.label
      assert_equal 'string', custom_attribute.attribute_type
      assert_equal 'select', custom_attribute.html_tag
      assert_equal 'my prompt', custom_attribute.prompt
      assert_equal 'value5', custom_attribute.default_value
      assert_equal %w(value1 value2 value5), custom_attribute.valid_values
      assert_equal({'class' => 'myclass', 'style' => 'color: red'}, custom_attribute.input_html_options)
      assert_equal({'class' => 'wrapper-class', 'style' => 'color: blue'}, custom_attribute.wrapper_html_options)
      assert_equal @transactable_type.id, custom_attribute.target_id
      assert_equal @transactable_type.class.name, custom_attribute.target_type
      assert_equal @instance.id, custom_attribute.instance_id
    end
  end

  should 'get list of custom attributes' do
    get :index, transactable_type_id: @transactable_type.id
    assert_response :success
  end

  should 'get edit form' do
    @custom_attribute = FactoryGirl.create(:custom_attribute, target: @transactable_type)
    get :edit, transactable_type_id: @transactable_type.id, id: @custom_attribute.id
    assert_response :success
  end

  should 'update custom attributes' do
    @custom_attribute = FactoryGirl.create(:custom_attribute, target: @transactable_type)
    put :update, transactable_type_id: @transactable_type.id, id: @custom_attribute.id, custom_attribute: { label: 'New Label' }
    assert_response :redirect
    assert_equal 'New Label', assigns(:custom_attribute).label
  end
end
