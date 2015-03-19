module LiquidFilters

  def shorten_url(url)
    Rails.env.development? ? url : Googl.shorten(url).short_url
  end

  def translate_property(property, target_acting_as_set)
    translate("simple_form.labels.#{target_acting_as_set.translation_key_suffix}.#{property}")
  end

  def translate(key, options={})
    I18n.t(key, options.deep_symbolize_keys)
  end
  alias_method :t, :translate

  def filter_text(text)
    if PlatformContext.current.instance.apply_text_filters
      @text_filters ||= TextFilter.pluck(:regexp, :replacement_text, :flags)
      @text_filters.each { |text_filter| text.gsub!(Regexp.new(text_filter[0], text_filter[2]), text_filter[1]) }
      text
    else
      text
    end
  end

  def custom_sanitize(html)
    if PlatformContext.current.instance.custom_sanitize_config.present?
      @custom_sanitizer ||= CustomSanitizer.new(PlatformContext.current.instance.custom_sanitize_config)
      @custom_sanitizer.sanitize(html).html_safe
    else
      html
    end
  end

end

