# frozen_string_literal: true
module Api
  class V4::TransactablesController < V4::BaseController
    include CoercionHelpers::Controller
    before_action :find_transactable_type
    skip_before_action :require_authentication
    skip_before_action :require_authorization
    before_action :coerce_pagination_params

    def index
      params[:v] = 'listing_mixed'
      search_params = params
      @searcher = InstanceType::Searcher::GeolocationSearcher::Listing.new(@transactable_type, search_params).tap(&:invoke)
      render json: ApiSerializer.serialize_collection(
        @searcher.results.includes(categories: [:parent]),
        include: ['categories', 'action-type', 'action-type.pricings'],
        meta: { total_entries: @searcher.result_count, total_pages: @searcher.total_pages },
        links: pagination_links,
        namespace: ::V3
      )
    end

    private

    def find_transactable_type
      @transactable_type = TransactableType.includes(:custom_attributes).friendly.find_by(id: params[:transactable_type_id]) || TransactableType.includes(:custom_attributes).first
    end

    def result_view
      return @result_view = 'index' if PlatformContext.current.custom_theme.present?
      return @result_view = 'community' if PlatformContext.current.instance.is_community?
      @result_view = params[:v].presence
      @result_view = @result_view.in?(@transactable_type.available_search_views) ? @result_view : @transactable_type.default_search_view
    end

    def pagination_links
      page = params[:page].to_pagination_number
      query = params.except(:page, :controller, :action)
      {
        first: api_transactables_url(query.merge(page: 1)),
        last: api_transactables_url(query.merge(page: @searcher.total_pages)),
        prev: page > 1 ? api_transactables_url(query.merge(page: page - 1)) : nil,
        next: page < @searcher.total_pages ? api_transactables_url(query.merge(page: page + 1)) : nil
      }
    end
  end
end