class SitemapNodeUpdateJob < Job
  include Job::LongRunning

  def after_initialize(action, object)
    @action = action
    @object = object
  end

  def perform
    @object.instance.domains.each do |domain|
      self.send(@action, domain)
    end
  end

  def create(domain)
    sitemap_xml = get_sitemap_xml(domain)

    closing_comment_mark = sitemap_xml.xpath("//comment()[contains(.,'/#{node_klass.comment_mark}')]").first
    closing_comment_mark.add_previous_sibling(node(domain).to_xml.squish)

    save_changes!(domain, sitemap_xml)
  end

  def update(domain)
    sitemap_xml = get_sitemap_xml(domain)
    
    outdated_node = sitemap_xml.at(find_node_by_loc(node(domain).location)).parent
    previous_node = outdated_node.previous_element

    outdated_node.remove
    previous_node.add_next_sibling(node(domain).to_xml.squish)

    save_changes!(domain, sitemap_xml)   
  end

  def destroy(domain)
    sitemap_xml = get_sitemap_xml(domain)
    to_be_deleted_node = sitemap_xml.at(find_node_by_loc(node(domain).location)).parent
    to_be_deleted_node.remove

    save_changes!(domain, sitemap_xml)
  end

  private

  def find_node_by_loc(loc)
    "urlset url loc:contains('#{loc}')"
  end

  def get_sitemap_xml(domain)
    Nokogiri::XML(domain.sitemap)
  end

  def node(domain)
    @node ||= node_klass.new(domain.url, @object)
  end

  def node_klass
    SitemapService.node_class_for_object(@object)
  end

  def save_changes!(domain, sitemap_xml)
    SitemapService.save_changes!(domain, sitemap_xml)
  end
end