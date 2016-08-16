class DB
  @@pages = nil

  def self.pages
    if @@pages.nil?
      page1 = {slug: '', template: 'template1'}
      page2 = {slug: 'a', parent: page1, template: 'template1'}
      page3 = {slug: 'b', parent: page2, template: 'template1'}
      page4 = {slug: 'c', parent: page2, template: 'template2'}
      page5 = {slug: 'd', parent: page3, template: 'template2'}
      page6 = {slug: 'e', parent: page5, template: 'template2'}
      page7 = {slug: 'f', parent: page6, template: 'template1'}
      @@pages = [page1, page2, page3, page4, page5, page6, page7]

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
    self.pages.select { |page| !page[:parent].nil? && page[:slug] == slug && page[:parent][:slug] == parent[:slug] }.first
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
      self.x(page[:parent]) + '/' + page[:slug]
    end
  end

  def self.root
    self.pages.select do |page|
      page[:parent].nil?
    end.first
  end

  def self.tree(page)
    page[:children] = self.pages.select do |pg|
      pg[:parent] == page
    end

    page[:children].each do |child|
      self.tree child
    end
    page
  end
end