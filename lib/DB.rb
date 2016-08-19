require 'rdf/turtle'

class DB
  @@pages = nil

  def self.pages
    if @@pages.nil?
      graph = RDF::Graph.load("lib/DB.ttl", format:  :ttl)

      @@pages = graph.subjects.map do |subject|
        slug = self.get_object(graph, subject, "http://data.parliament.uk/schema/parl#slug").to_s
        parent = self.get_object(graph, subject, "http://data.parliament.uk/schema/parl#parent")
        template = self.get_object(graph, subject, "http://data.parliament.uk/schema/parl#template").to_s
        type = self.get_object(graph, subject, "http://data.parliament.uk/schema/parl#type").to_s
        title = self.get_object(graph, subject, "http://data.parliament.uk/schema/parl#title").to_s

        {
            id: subject,
            slug: slug,
            parent: parent,
            template: template,
            type: type,
            title: title
        }
      end

      @@pages.each do |page|
        page[:path] = self.generate_path page
      end

      DB.tree DB.root
    end

    @@pages
  end

  def self.reload
    @@pages = nil
  end

  def self.find_root_page_by_slug(slug)
    self.pages.select { |page| page[:parent].nil? && page[:slug] == slug }.first
  end

  def self.find_page_by_slug_and_parent(slug, parent)
    self.pages.select do |page|
      page_parent = self.find_parent(page[:parent])
      !page[:parent].nil? && page[:slug] == slug && page_parent[:slug] == parent[:slug]
    end.first
  end

  def self.find_parent(parent_id)
    self.pages.select{ |pg| pg[:id] == parent_id }.first
  end

  def self.find_ancestry_by_path path
    path ||= ''

    path_components = [''] + path.split('/') #refactor
    page = nil

    pages = path_components.map.with_index do |component, index|
      if index == 0
        page = DB.find_root_page_by_slug component
      else
        page = DB.find_page_by_slug_and_parent component, page
      end
    end

    if pages.any? { |page| page.nil? }
      nil
    else
      pages
    end
  end

  def self.find_page_by_path path
    pages = self.find_ancestry_by_path path

    if pages.nil?
      raise ActionController::RoutingError.new('not found')
    end
    pages.last
  end

  def self.generate_path(page)
    path = self.generate_parent_path(page)

    path == '' ? '/' : path
  end

  def self.generate_parent_path(page)
    if page[:parent].nil?
      ''
    else
      parent = @@pages.select{ |pg| pg[:id] == page[:parent] }.first
      self.generate_parent_path(parent) + '/' + page[:slug]
    end
  end

  def self.root
    self.pages.select do |page|
      page[:parent].nil?
    end.first
  end

  def self.tree(page)
    page[:children] = self.pages.select do |pg|
      pg[:parent] == page[:id]
    end

    page[:children].each do |child|
      self.tree child
    end
    page
  end

  private

  def self.get_object(graph, subject, predicate)
    pattern = RDF::Query::Pattern.new(
        subject,
        RDF::URI.new(predicate),
        :object)
    graph.first_object(pattern)
  end
end