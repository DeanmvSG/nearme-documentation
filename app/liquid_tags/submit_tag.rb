class SubmitTag < Liquid::Tag
  include AttributesParserHelper

  Syntax = /(#{Liquid::QuotedFragment}+)\s*/o

  def initialize(tag_name, markup, tokens)
    super
    if markup =~ Syntax
      @value = $1.sub(/^["']/, '').sub(/["']$/, '')
      @attributes = create_initial_hash_from_liquid_tag_markup(markup)
    else
      raise SyntaxError.new('Invalid syntax for Input tag - must pass field name')
    end
  end

  def render(context)
    # drop for form_builder defined in form_builder_to_liquid_monkeypatch.rb
    @attributes = normalize_liquid_tag_attributes(@attributes, context)
    @form =  context["form_object"].source
    @value = values_value(@value, context)
    @form.submit(@value, @attributes).html_safe
  end

end
