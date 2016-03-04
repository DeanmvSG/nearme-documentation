# Usage: {% featured_items target: users, amount: 6 %}
# or: {% featured_items target: services, amount: 6, type: Boat %}
#

class FeaturedItemsTag < Liquid::Tag
  def initialize(tag_name, arguments, context)
    super

    if arguments =~ /(#{::Liquid::QuotedFragment}+)/
      @arguments = arguments
    else
      raise SyntaxError.new("Syntax Error - Valid syntax: {% featured_items [arguments] %}")
    end
  end

  def render(context)
    @context = context
    @view = @context.registers[:view]
    @attributes = {}

    @arguments.scan(Liquid::TagAttributes) do |key, value|
      @attributes[key] = value.gsub(/^'|"/, '').gsub(/'|"$/, '')
    end

    @attributes.symbolize_keys!

    routes = Rails.application.routes.url_methods
    
    params = { target: @attributes[:target], amount: @attributes[:amount] }
    params.merge!(type: @attributes[:type]) if @attributes[:type].present?
    route = routes.featured_items_path(params)
    
    uuid = SecureRandom.uuid

    html = @view.content_tag(:div, "", class: "featured-items-#{uuid}")
    script = "<script>window.onload = function () { $.get('#{route}', function (data) { $('.featured-items-#{uuid}').html(data) }); } </script>"

    [html, script].join.html_safe
  end
end

class RenderFeaturedItemsTag < Liquid::Tag
  def initialize(tag_name, arguments, context)
    super
  end

  def render(context)
    context.registers[:action_view].render_featured_items
  end
end
