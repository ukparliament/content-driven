require 'rdf/turtle'

class DB
  @@pages = nil

  def self.pages
    if @@pages.nil?
      graph = RDF::Graph.load("lib/DB.ttl", format:  :ttl)

      @@pages = graph.subjects.map do |subject|
        slug_pattern = RDF::Query::Pattern.new(
            subject,
            RDF::URI.new("http://data.parliament.uk/schema/parl#slug"),
            :slug
        )
        slug = graph.first_literal(slug_pattern).to_s
        parent_pattern = RDF::Query::Pattern.new(
            subject,
            RDF::URI.new("http://data.parliament.uk/schema/parl#parent"),
            :parent
        )
        parent = graph.first_object(parent_pattern)

        {
            id: subject,
            slug: slug,
            parent: parent
        }
      end
      #
      # page1 = {slug: ''}
      # page2 = {slug: 'a', parent: page1}
      # page3 = {slug: 'b', parent: page2}
      # page4 = {slug: 'c', parent: page2}
      # page5 = {slug: 'd', parent: page3}
      # page6 = {slug: 'e', parent: page5}
      # page7 = {slug: 'f', parent: page6}
      # @@pages = [page1, page2, page3, page4, page5, page6, page7]

      @@pages.each do |page|
        page[:path] = self.generate_path page
      end

      DB.tree DB.root
    end

    @@pages
  end

  def self.find_page_by_slug(slug)
    self.pages.select { |page| page[:parent].nil? && page[:slug] == slug }.first
  end

  def self.find_page_by_slug_and_parent(slug, parent)
    self.pages.select do |page|
      page_parent = self.find_parent(page[:parent])
      !page[:parent].nil? && page[:slug] == slug && page_parent[:slug] == parent[:slug]
    end.first
  end

  def self.find_parent(parent_id)
    self.pages.select{ |pg| pg[:id] == parent_id}
  end

  def self.find_ancestry_by_path path
    path ||= ''

    path_components = [''] + path.split('/') #refactor
    page = nil

    pages = path_components.map.with_index do |component, index|
      if index == 0
        page = DB.find_page_by_slug component
      else
        page = DB.find_page_by_slug_and_parent component, page
      end
    end

    if pages.any? { |page| page.nil? }
      raise 'Not Found'
    end

    pages
  end

  def self.find_page_by_path path
    pages = self.find_ancestry_by_path path

    pages.last
  end

  def self.generate_path(page)
    path = self.x(page)

    path == '' ? '/' : path
  end

  def self.x(page)
    if page[:parent].nil?
      ''
    else
      parent = self.pages.select{ |pg| pg[:id] == page[:parent] }
      self.x(parent) + '/' + page[:slug]
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
end