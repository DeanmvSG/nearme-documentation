module ApplicationHelper

  include FormHelper
  include TooltipHelper
  include CurrencyHelper
  include FileuploadHelper
  include SharingHelper

  def title(page_title, show_title = true)
    content_for(:title) { h(page_title.to_s) }
    @show_title = show_title
  end

  def meta_title(name)
    content_for(:meta_title) { h(name.to_s) }
  end

  def title_tag
    (show_title? ? content_for(:title) : "Find office space. Rent office space. Get to work.") + 
      (additional_meta_title ? " | " + additional_meta_title : '')
  end

  def additional_meta_title
    content_for?(:meta_title) ? content_for(:meta_title) : current_instance.try(:meta_title)
  end

  def legacy(is_legacy = true)
    @is_legacy = is_legacy
  end

  def legacy?
    !defined?(@is_legacy) || @is_legacy
  end

  def show_title?
    @show_title
  end

  def apply_analytics?
    # Enable mixpanel in all environments. We use a different account for
    # production.
    true
  end

  def stripe_public_key
    DesksnearMe::Application.config.stripe_public_key
  end

  def truncate_with_ellipsis(body, length, html_options = {})

    body ||= ''
    if body.size > length

      size = 0
      body = body.squish

      truncated_body = body.split.reject do |token|
        size += token.size + 1
        size > length
      end

      excess_body = (body.split - truncated_body)

      content_tag(:p, html_options) do
        truncated_body.join(" ").html_safe +
        content_tag(:span, "&hellip;".html_safe, :class => 'truncated-ellipsis').html_safe +
        content_tag(:span, excess_body.join(" ").html_safe, :class => 'truncated-text hidden').html_safe
      end

    else
      body
    end

  end

  def get_return_to_url
     in_signed_in_or_sign_up? ? {} : {:return_to => "#{request.protocol}#{request.host_with_port}#{request.fullpath}"}
  end

  def in_signed_in_or_sign_up?
    in_signed_in? || in_sign_up?
  end

  def in_signed_in?
    params[:controller]=='sessions'
  end

  def in_sign_up?
    params[:controller]=='registrations'
  end

  def link_to_once(*args, &block)
    options = args.first || {}
    html_options = args.second || {}

    unless html_options.key?(:disable_with) then html_options[:disable_with] = "Loading..." end
    if block_given?
      link_to(capture(&block), options, html_options)
    else
      link_to(options, html_options)
    end
  end
end
