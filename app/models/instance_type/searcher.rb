module InstanceType::Searcher

  attr_reader :results, :transactable_type

  def result_count
    if self.class.to_s =~ /Elastic/
      @search_results_count
    else
      @result_count ||= count_query(results.distinct)
    end
  end

  # Hack to get proper count from grouped querry
  def count_query(query)
    query = "SELECT count(*) AS count_all FROM (#{query.to_sql}) x"
    Spree::Product.count_by_sql(query)
  end

  def max_price
    begin
      @max_fixed_price ||= results.maximum(:fixed_price_cents).to_i / 100
      @max_fixed_price > 0 ? @max_fixed_price + 1 : @max_fixed_price
    rescue
      0
    end
  end

  def paginate_results(page, per_page)
    page ||= 1
    @results = @results.paginate(page: page, per_page: per_page)
  end

end
