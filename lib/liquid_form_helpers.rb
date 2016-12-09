module LiquidFormHelpers
  # http://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-options_for_select
  def options_for_select(*args)
    form_helper.options_for_select(*args)
  end

  def options_from_collection_for_select(collection, selected = nil)
    if selected.present?
      collection.unshift first_select_option('- reset filter -')
    else
      collection.unshift first_select_option
    end

    collection.map do |item|
      label = item.label
      is_selected = Array(selected).include?(item.key)
      css_class = 'filter-no-results' if item.disabled
      data = { 'results-number' => item.value }

      content_tag :option, label, selected: is_selected, value: item.key, class: css_class, data: data
    end
  end

  private

  def first_select_option(label = 'Please select')
    OpenStruct.new(label: label, key: '', value: 0, disabled: false)
  end

  class RailsFormHelpersProxy
    include ActionView::Helpers::FormOptionsHelper
  end

  def form_helper
    RailsFormHelpersProxy.new
  end
end
