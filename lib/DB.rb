require 'rdf/turtle'

class DB
  @@pages = nil

  def self.pages
    if @@pages.nil?
      graph = self.query(
                  'PREFIX parl: <http://data.parliament.uk/schema/parl#>
                  CONSTRUCT {
                      ?s
                          parl:slug ?slug ;
                          parl:parent ?parent ;
                          parl:template ?template ;
                          parl:type ?type ;
                          parl:title ?title .
                  }
                  WHERE {
                    ?s a parl:Page ;
                          parl:template ?template ;
                          parl:title ?title .
                      OPTIONAL
                      {
                          ?s parl:slug ?slug .
                      }
                      OPTIONAL
                      {
                         ?s parl:parent ?parent .
                      }
                      OPTIONAL
                      {
                          ?s parl:type ?type .
                      }
                      OPTIONAL
                      {
                          ?s parl:text ?text .
                      }
                  }
                ')

      @@pages = graph.subjects.map do |subject|
        slug = get_object(graph, subject, "http://data.parliament.uk/schema/parl#slug").to_s
        parent = get_object(graph, subject, "http://data.parliament.uk/schema/parl#parent")
        template = get_object(graph, subject, "http://data.parliament.uk/schema/parl#template").to_s
        type = get_object(graph, subject, "http://data.parliament.uk/schema/parl#type").to_s
        title = get_object(graph, subject, "http://data.parliament.uk/schema/parl#title").to_s

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

  def self.find_templates
    graph = self.query('
              PREFIX parl: <http://data.parliament.uk/schema/parl#>
              CONSTRUCT {
                   _:x parl:template ?template
              }
              WHERE {
                  SELECT DISTINCT ?template WHERE {
                  ?s parl:template ?template .
                }
              }
            ')
    graph.subjects.map do |subject|
      get_object(graph, subject, "http://data.parliament.uk/schema/parl#template").to_s
    end
  end

  def self.potential_parents
    graph = self.query('
              PREFIX parl: <http://data.parliament.uk/schema/parl#>
              CONSTRUCT {
                   _:x
                      parl:page ?s ;
                      parl:title ?title .
              }
              WHERE {
                  SELECT ?s ?title WHERE {
                      ?s
                          a parl:Page ;
                          parl:title ?title .
                }
              }
            ')
    graph.subjects.map do |subject|
      uri = get_object(graph, subject, "http://data.parliament.uk/schema/parl#page")
      title = get_object(graph, subject, "http://data.parliament.uk/schema/parl#page")
      {
          uri: uri,
          title: title
      }
    end
  end

  def self.query(sparql)
    RDF::Graph.new << SPARQL::Client.new(ContentDriven::Application.config.database).query(sparql)
  end

  def self.get_object(graph, subject, predicate)
    pattern = RDF::Query::Pattern.new(
        subject,
        RDF::URI.new(predicate),
        :object)
    graph.first_object(pattern)
  end

  private_class_method :get_object
end