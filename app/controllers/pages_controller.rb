# frozen_string_literal: true
class PagesController < ApplicationController
  layout :resolve_layout
  respond_to :html

  skip_before_filter :redirect_unverified_user, unless: -> { page.require_verified_user? }

  def show
    @data_source_contents_scope = DataSourceContent.joins(:page_data_source_contents).where(page_data_source_contents: { page: page, slug: [nil, [params[:slug], params[:slug2], params[:slug3]].compact.join('/')] })
    @data_source_last_update = @data_source_contents_scope.maximum(:updated_at)
    @data_source_contents = @data_source_contents_scope.paginate(page: params[:page].to_i.zero? ? 1 : params[:page].to_i, per_page: 20)
    @seo_params = SeoParams.create(params)
    if page.redirect?
      redirect_to page.redirect_url, status: page.redirect_code
    elsif params[:simple]
      respond_to do |format|
        format.html { render :simple, platform_context: [platform_context.decorate] }
      end
    elsif page.layout_name.blank? || params[:nolayout]
      assigns = {}
      assigns['params'] = params.except(*Rails.application.config.filter_parameters)
      assigns['current_user'] = current_user
      assigns['platform_context'] = PlatformContext.current.decorate
      assigns['data_source_contents'] = @data_source_contents
      render text: Liquid::Template.parse(page.content).render(assigns, registers: { action_view: self }, filters: [LiquidFilters])
    else
      respond_to do |format|
        format.html { render :show, layout: page.layout_name }
      end
    end
  end

  def redirect
    redirect_to pages_path(params[:slug]), status: 301
  end

  private

  def page
    return @page if @page

    @page = platform_context.theme.pages.find_by(slug: Page.possible_slugs([params[:slug], params[:slug2], params[:slug3]].compact.join('/'), params[:format]))
    @page = platform_context.theme.pages.find_by(slug: Page.possible_slugs([params[:slug], params[:slug2]].compact.join('/'), params[:format])) if @page.nil?
    @page = platform_context.theme.pages.find_by(slug: Page.possible_slugs(params[:slug], params[:format])) if @page.nil?

    raise Page::NotFound unless @page.present?

    @page
  end

  # Layout per action
  def resolve_layout
    case action_name
    when 'host_signup'
      'landing'
    when 'show'
      layout_name
    else
      false
    end
  end
end
