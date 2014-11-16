# LiquidView is a action view extension class. You can register it with rails
# and use liquid as an template system for .liquid files
#
# Example
#
#   ActionView::Base::register_template_handler :liquid, LiquidView
class LiquidView
  PROTECTED_ASSIGNS = %w( template_root response _session template_class action_name request_origin session template
                          _response url _request _cookies variables_added _flash params _headers request cookies
                          ignore_missing_templates flash _params logger before_filter_chain_aborted headers )
  PROTECTED_INSTANCE_VARIABLES = %w( @_request @controller @_first_render @_memoized__pick_template @view_paths
                                     @helpers @assigns_added @template @_render_stack @template_format @assigns )

  def self.call(template)
    "LiquidView.new(self).render(#{template.source.inspect}, local_assigns)"
  end

  def initialize(view)
    @view = view
  end

  def render(source, local_assigns = {})
    @view.controller.headers["Content-Type"] ||= 'text/html; charset=utf-8'

    assigns = @view.assigns.reject{ |k,v| PROTECTED_ASSIGNS.include?(k) }

    assigns['platform_context'] = PlatformContext.current.decorate
    assigns['current_year'] = Date.current.year

    if content_for_layout = @view.instance_variable_get("@content_for_layout")
      assigns['content_for_layout'] = content_for_layout
    elsif @view.content_for?(:layout)
      assigns["content_for_layout"] = @view.content_for(:layout)
    end
    assigns.merge!(local_assigns.stringify_keys)

    controller = @view.controller

    tags = tags_from_controller(controller)
    register_tags(tags)

    liquid = Liquid::Template.parse(source)

    filters = filters_from_controller(controller)

    liquid.render(assigns, :filters => filters, :registers => {:action_view => @view, :controller => @view.controller}).html_safe
  end

  def compilable?
    false
  end

  def filters_from_controller(controller)
    filters = if controller.respond_to?(:liquid_filters, true)
                controller.send(:liquid_filters)
              elsif controller.respond_to?(:master_helper_module)
                [controller.master_helper_module]
              else
                [controller._helpers]
              end

    filters
  end

  def register_tags(tags)
    tags.keys.each do |key|
      Liquid::Template.register_tag(key, tags.fetch(key))
    end
  end

  def tags_from_controller(controller)
    tags = if controller.respond_to?(:liquid_tags, true)
             controller.send(:liquid_tags)
           else
             {}
           end

    tags
  end
end
