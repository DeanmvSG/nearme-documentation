class LimitedTextInput < SimpleForm::Inputs::TextInput
  include LimitedInput

  def input
    limiter = prepare_limiter
    "#{@builder.text_area(attribute_name, input_html_options)}#{limiter}".html_safe
  end
end
