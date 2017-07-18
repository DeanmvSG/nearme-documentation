# frozen_string_literal: true
class RenderCustomPage
  def initialize(controller:, page:, params: {}, submitted_form: nil)
    @controller = controller
    @page = page
    @params = params
    @submitted_form = submitted_form
  end

  def render
    setup_page
    setup_datasource
    setup_params
    setup_forms
    setup_authorizer
    http_response
  end

  private

  def setup_page
    @controller.instance_variable_set(:'@page', @page)
  end

  def setup_datasource
    data_source_contents_scope = DataSourceContent.joins(:page_data_source_contents).where(page_data_source_contents: { page: @page, slug: [nil, [@params[:slug], @params[:slug2], @params[:slug3]].compact.join('/')] })
    @controller.instance_variable_set(:'@data_source_last_update', data_source_contents_scope.maximum(:updated_at))
    @controller.instance_variable_set(:'@data_source_contents', data_source_contents_scope.paginate(page: @params[:page].to_i.zero? ? 1 : @params[:page].to_i, per_page: 20))
  end

  def setup_params
    @controller.instance_variable_set(:'@seo_params', SeoParams.create(@params))
  end

  # fc.build(User.new) needs to be updated - we should do some sort of mapping - i.e. know that
  # form 'Update Transactable' should be initialize with current_user.transactables.where(id: params[:transactable_id])
  # etc.
  def setup_forms
    forms = {}
    forms.merge!(@submitted_form) if @submitted_form.present?
    forms = forms.with_indifferent_access
    @controller.instance_variable_set(:'@forms', forms)
  end

  def setup_authorizer
    return unless @page.admin_page?

    @controller.instance_variable_set(:'@authorizer', authorizer)
  end

  def authorizer
    InstanceAdminAuthorizer.new(@controller.current_user)
  end

  def http_response
    @controller.redirect_to(@page.redirect_url, status: @page.redirect_code) && return if @page.redirect?

    @controller.respond_to do |format|
      format.html do
        if @params[:simple]
          @controller.render 'pages/simple', platform_context: [platform_context.decorate]
        elsif @page.layout_name.blank? || @params[:nolayout]
          @controller.render 'pages/show', layout: false
        else
          @controller.render 'pages/show', layout: @page.layout_name
        end
      end

      format.json do
        @controller.headers['Content-Type'] = 'application/json'
        @controller.render 'pages/show', layout: false
      end
    end
  end
end