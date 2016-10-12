class InstanceType::Searcher::ProjectsSearcher
  include InstanceType::Searcher

  attr_reader :search

  def initialize(params, _current_user)
    @params = params
    @results = fetcher
  end

  def fetcher
    @fetcher  = Transactable.active.search_by_query([:name, :description, :properties], @params[:query])
    @fetcher = @fetcher.by_topic(selected_topic_ids).custom_order(@params[:sort])
    @fetcher = @fetcher.seek_collaborators if @params[:seek_collaborators] == '1'
    if @params[:sort] =~ /collaborators/i && selected_topic_ids.present?
      @fetcher = @fetcher.group('transactable_topics.id')
    end
    @fetcher
  end

  def topics_for_filter
    fetcher.map(&:topics).flatten.uniq
  end

  def selected_topic_ids
    @params[:topic_ids].select(&:present?) if @params[:topic_ids]
  end

  def search_query_values
    {
      query: @params[:query]
    }
  end

  def to_event_params
    { search_query: @params[:query], result_count: result_count }
  end
end
