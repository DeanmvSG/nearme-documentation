class WorkflowStep::SavedSearchWorkflow::BaseStep < WorkflowStep::BaseStep

  def initialize(saved_searches_ids)
    @saved_searches = SavedSearch.where(id: saved_searches_ids)
    raise 'There should be saved searches' if @saved_searches.empty?
  end

  def workflow_type
    'saved_search'
  end

  def enquirer
    raise 'Saved searches should belong to the same user' unless @saved_searches.map(&:user_id).uniq.size == 1
    @saved_searches.first.user
  end

  def data
    {
      saved_searches: @saved_searches,
      saved_searches_titles: @saved_searches.map { |ss| "'#{ss.title}'" }.join(', ')
    }
  end

end

