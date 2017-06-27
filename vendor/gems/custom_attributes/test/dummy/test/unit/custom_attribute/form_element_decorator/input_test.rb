require 'test_helper'

class CustomAttributes::CustomAttribute::FormElementDecorator::InputTest < ActionView::TestCase

  context 'limit' do

    should 'know if attribute is not limited at all' do
      assert_nil CustomAttributes::CustomAttribute::FormElementDecorator::Input.new(stub("validation_rules" => {})).limit
    end

    should 'know if attribute is limited but with minimal length' do
      assert_nil CustomAttributes::CustomAttribute::FormElementDecorator::Input.new(stub("validation_rules" => { "length" => { "minimum" => 50 } })).limit
    end

    should 'know when attribute is limited as string' do
      input = CustomAttributes::CustomAttribute::FormElementDecorator::Input.new(stub("validation_rules" => { "length" => { "maximum" => 50 } }))
      assert_equal 50, input.limit
      assert_equal :limited_string, input.options[:as]
    end

    should 'know when attribute is limited as text' do
      input = CustomAttributes::CustomAttribute::FormElementDecorator::Input.new(stub("validation_rules" => { "length" => { "maximum" => 51 } }))
      assert_equal 51, input.limit
      assert_equal :limited_text, input.options[:as]
    end

  end

  context 'options with custom as' do

    should 'return correct custom_as hash with options' do
      expected_hash = {
        as: :limited_string,
        limit: 50,
        input_html: { :maxlength => 50 }
      }
      assert_equal expected_hash, CustomAttributes::CustomAttribute::FormElementDecorator::Input.new(stub("validation_rules" => { "length" => { "maximum" => 50 } })).options
    end
  end

end
